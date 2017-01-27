require 'test_helper'

class PostTest < ActiveSupport::TestCase
  include GroongaClientModel::TestHelper

  test ".create(Hash)" do
    post = Post.create(:title => "Hello")
    assert_equal("Hello", Post.find(post.id).title)
  end

  test ".create([Hash])" do
    posts = Post.create([{:title => "Hello1"}, {:title => "Hello2"}])
    assert_equal(["Hello1", "Hello2"],
                 posts.collect {|post| Post.find(post.id).title})
  end
end
