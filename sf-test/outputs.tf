output "apmserver" {
  value = "${aws_instance.apmserver.public_ip}"
}

