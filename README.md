# gitlab-license
GitLab gem and Ruby script that allows you to easily generate and verify GitLab EE licenses.

## Installation

Simply run
```
gem install gitlab-license
```
## Usage (easy mode)

1. Launch the `gitlabgen1.rb` script in a Ruby shell
    ```bash
    sudo ruby gitlabgen1.rb
    ```
2. Enter all the requested info.
  * Remember to replace GitLab's public key with the one in this repo inside `/opt/gitlab/embedded/service/gitlab-rails/.license_encryption_key.pub` if you want the generated license to work in a GitLab production system. Keep in mind that the legallity of this action is questionable at best.
3. Copy the output and paste it into GitLab, and you're done!
