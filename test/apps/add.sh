#!/bin/bash
#
# Copyright (C) 2021  Sutou Kouhei <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

if [ $# -eq 0 ]; then
  echo "Usage: $0 RAILS_VERSION [OPTIONS...]"
  echo " e.g.: $0 6.2"
  exit 1
fi

set -eux

rails_version=$1
shift

rm -rf blog
rails _${rails_version}_ new blog \
      --skip-active-record \
      --skip-spring \
      --skip-webpack-install
pushd blog
cat <<GEMFILE >> Gemfile
gem 'groonga-client-model', path: '../../../'
gem 'groonga-client', path: '../../../../groonga-client'

group :development, :test do
  gem 'factory_bot_rails'
end
GEMFILE
bin/bundle update
sed -i'' -e 's/"yarn"/"yarnpkg", "yarn"/g' bin/yarn
PATH=$PWD/bin:$PATH rails webpacker:install
PATH=$PWD/bin:$PATH bin/rails generate scaffold post title:string body:text
cat <<TEST_HELPER >> test/test_helper.rb

require "groonga_client_model/test_helper"
class ActiveSupport::TestCase
  include GroongaClientModel::TestHelper
  include FactoryBot::Syntax::Methods
end
TEST_HELPER
sed -i'' -e 's/posts(:one)/create(:post)/g' test/**/*_test.rb
if PATH=$PWD/bin:$PATH rails --tasks | grep -q test:all; then
  PATH=$PWD/bin:$PATH rails test:all
else
  PATH=$PWD/bin:$PATH rails test
  PATH=$PWD/bin:$PATH rails test:system
fi
sed -i'' -e 's/^ruby .*//g' Gemfile
rm .ruby-version
rm Gemfile.lock
rm yarn.lock
echo <<GITIGNORE >> .gitignore

/.ruby-version
/Gemfile.lock
/yarn.lock
GITIGNORE
rm -rf .git
popd
rm -rf rails${rails_version}
mv blog rails${rails_version}
git add rails${rails_version}
