# SimpleFlag

Simple but powerful feature flag implementation in 90 LOC.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_flag'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install simple_flag

## Usage

### Configuration

```ruby
FEATURE = SimpleFlag.new do |feature|
  feature.define(:new_user_profile) do |user_id:|
    Admin.where(user_id: user_id).exists?
  end
  feature.define(:third_party_analytics) do
    not Rails.env.production?
  end
end
```

### Usage in app code

```ruby
class ProfilesController < ApplicationController
  def show
    FEATURE.with(:new_user_profile, user_id: current_user.id) do
      return render :new_user_profile, locals: { user: NewUserProfilePresenterV2.new(current_user) }
    end
    render :show, locals: { user: UserProfilePresenterV1.new(current_user) }
  end
end
```

### Testing with before...after

```ruby
describe "User profiles" do
  after { FEATURE.reset_all_overrides }

  context "with new_user_profile feature enabled" do
    before { FEATURE.override(:new_user_profile, true) }
    it "renders new profile"
  end

  context "with new_user_profile feature disabled" do
    before { FEATURE.override(:new_user_profile, false) }
    it "renders old profile"
  end
end
```

### Testing with inline block

```ruby
it "shows new user profile" do
  FEATURE.override_with(:new_user_profile, true) do
    expect( FEATURE.active?(:new_user_profile) ).to be_truthy
  end
  expect( FEATURE.active?(:new_user_profile) ).to be_falsy
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wojtha/simple_flag.

