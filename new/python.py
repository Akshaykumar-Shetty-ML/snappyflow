from github import Github
# tested
# First create a Github instance:

# using username and password
g = Github("theakshashetty", "Blueshirt@123")


def login(user, passwd):
    """
    git login
    :param user:
    :param passwd:
    :return:
    """
    git = Github(user, passwd)
    return git


def get_user(git):
    """
    get user
    :param git:
    :return:
    """
    user = g.get_user()
    return user


def create_repo(user, name):
    repo = user.create_repo(name)
    return repo


def get_repo(user, repo):
    """
    get repo
    :param user:
    :param repo:
    :return:
    """
    repo = user.get_repo("snappy")
    return repo


def commit_file(repo, file, msg, content):
    """
    commit files
    :param repo:
    :param file:
    :param msg:
    :param content:
    :return:
    """
    repo.create_file("/{}".format(file), msg, file)


def create_get_release(repo):
    """
    create release tag
    :param repo:
    :return:
    """
    repo.create_git_release(
            "v1.0",
            "v1.0",
            "snappyflow",
            )


def get_release_tag(repo):

    p = repo.get_releases()
    for release in p:
        print 'release ', release
        print 'release.name ', release.tag_name


if __name__ == '__main__':
    git = login("theakshashetty", "Blueshirt@123")
    user = get_user(git)
    repo = create_repo("user", "snappyflow")
    create_get_release(repo)
