provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  #shared_credentials_file = "${var.credentialsfile}"
  region     = "${var.region}"
}

data "aws_ami" "ubuntu1604" {
  most_recent = true
  owners = [
    "099720109477"]
  # Canonical

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }
}

resource "aws_default_vpc" "default_vpc" {}

resource "aws_security_group" "allow_all" {
  name = "${var.stackname}"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_default_vpc.default_vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

locals {
    sshkey_path = "${var.ssh_key_name}.pem"
}

resource "aws_instance" "apmserver" {
  ami = "${data.aws_ami.ubuntu1604.id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.ssh_key_name}"
  associate_public_ip_address = true
  tags {
    Name = "apmserver"
    Stack = "${var.stackname}"
  }
  root_block_device {
    delete_on_termination = true
  }
  security_groups = [
    "${aws_security_group.allow_all.name}"
  ]

    provisioner "file" {
     connection {
      type = "ssh"
      user = "${var.ssh_user}" 
      private_key = "${file("shared-SSHkey-fordemo.pem")}"
    }
    source      = "guestbook.tar.gz"
    destination = "/home/ubuntu/guestbook.tar.gz"
  }

   provisioner "local-exec" {
     command = "echo \"`ifconfig ens160 | grep \"inet \" | awk -F'[: ]+' '{ print $3 }'`\" > local_ip.txt"
   }

   provisioner "file" {
     connection {
      type = "ssh"
      user = "${var.ssh_user}"
      private_key = "${file("shared-SSHkey-fordemo.pem")}"
    }
    source      = "local_ip.txt"
    destination = "/home/ubuntu/local_ip.txt"
   }
   
   provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "${var.ssh_user}"
      private_key = "${file("shared-SSHkey-fordemo.pem")}"
    }
    inline = [
      "sudo -S apt-get update",
      "sudo -S apt-get install -y python-pip build-essential libssl-dev libffi-dev python-dev default-jre git libmysqlclient-dev",
      "echo 'mysql-server mysql-server/root_password password ${var.mysqlrootpassword}' | sudo -S debconf-set-selections",
      "echo 'mysql-server mysql-server/root_password_again password ${var.mysqlrootpassword}' | sudo -S debconf-set-selections",
      "sudo -S apt-get install -y mysql-server",
      "cd /home/ubuntu && tar -xf guestbook.tar.gz",
      "cd /home/ubuntu/guestbook/guestbook && sudo pip install -r requirements.txt",
      "mysql -u root -p${var.mysqlrootpassword} -e \"CREATE DATABASE testdb;\"",
      "mysql -u root -p${var.mysqlrootpassword} -e \"GRANT ALL PRIVILEGES ON testdb.* TO 'root'@'%' IDENTIFIED BY 'maplelabs';\"",
      "mysql -u root -p${var.mysqlrootpassword} -e \"FLUSH PRIVILEGES;\"",
      "cd /home/ubuntu/guestbook/guestbook && sudo -S python manage.py makemigrations",
      "cd /home/ubuntu/guestbook/guestbook && sudo -S python manage.py migrate",
      "cd /home/ubuntu/ && sudo -S sed -i \"s/http:\\/\\/localhost:8200/http:\\/\\/`cat local_ip.txt`:8200/g\" /home/ubuntu/guestbook/guestbook/guestbook/settings.py",
      "cd /home/ubuntu && sudo -S wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.0.deb && sudo dpkg -i elasticsearch-6.2.0.deb",
      "sudo -S sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml",
      "cd /home/ubuntu && sudo -S wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-3.3.tgz && tar -xf apache-jmeter-3.3.tgz",
      "cd /home/ubuntu/guestbook/guestbook/sampledata && cp HTTP\\ Request.jmx input.csv /home/ubuntu/apache-jmeter-3.3",
      "echo \"`ifconfig eth0 | grep \"inet \" | awk -F'[: ]+' '{ print $4 }'`\" > remote_ip.txt && sed -i \"s/10.11.100.162/`cat remote_ip.txt`/g\" /home/ubuntu/apache-jmeter-3.3/HTTP\\ Request.jmx",
      "sudo -S crontab -l > tempcron && echo '*/5 * * * * sh /home/ubuntu/apache-jmeter-3.3/bin/jmeter.sh -n -t /home/ubuntu/apache-jmeter-3.3/HTTP\\ Request.jmx  -l /home/ubuntu/apache-jmeter-3.3/log.jtl -J users=10' >> tempcron && sudo -S crontab tempcron && rm tempcron",
      "echo \"`ifconfig eth0 | grep \"inet \" | awk -F'[: ]+' '{ print $4 }'`\" > remote_ip.txt && sed -i \"s/localhost/`cat remote_ip.txt`/g\" /home/ubuntu/guestbook/guestbook/templates/index.html",
      "sudo -S systemctl enable elasticsearch.service && sudo -S systemctl start elasticsearch.service",
      "sudo -S systemctl enable mysql.service && sudo -S systemctl start mysql.service",
      "cd /home/ubuntu/guestbook/guestbook && sudo -S python manage.py runserver 0:8000 &",    
    ]
  }
}

