require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe Pickle::Session do
  before do
    @session = Pickle::Session.new
  end

  describe "after storing a single user", :shared => true do
    it "original_models('user') should be array containing the original user" do
      @session.original_models('user').should == [@user]
    end

    describe "the original user should be retrievable with" do
      it "original_model('the user')" do
        @session.original_model('the user').should == @user
      end

      it "original_model('1st user')" do
        @session.original_model('1st user').should == @user
      end

      it "original_model('last user')" do
        @session.original_model('last user').should == @user
      end
    end

    describe "(found from db)" do
      before do
        @user.stub!(:id).and_return(100)
        @user.class.should_receive(:find).with(100).and_return(@user_from_db = @user.dup)
      end
    
      it "models('user') should be array containing user" do
        @session.models('user').should == [@user_from_db]
      end
  
      describe "user should be retrievable with" do
        it "model('the user')" do
          @session.model('the user').should == @user_from_db
        end

        it "model('1st user')" do
          @session.model('1st user').should == @user_from_db
        end

        it "model('last user')" do
          @session.model('last user').should == @user_from_db
        end
      end
    end
  end
  
  describe "#create_model" do
    before do
      @user = mock_model(User)
      Factory.stub!(:create).and_return(@user)
    end
    
    describe "('a user')" do
      def do_create_model
        @session.create_model('a user')
      end
  
      it "should call Factory.create('user', {})" do
        Factory.should_receive(:create).with('user', {}).and_return(@user)
        do_create_model
      end
      
      describe "after create," do
        before { do_create_model }
        
        it_should_behave_like "after storing a single user"
      end
    end
    
    describe "('1 user', 'foo: \"bar\", baz: \"bing bong\"')" do
      def do_create_model
        @session.create_model('1 user', 'foo: "bar", baz: "bing bong"')
      end
  
      it "should call Factory.create('user', {'foo' => 'bar', 'baz' => 'bing bong'})" do
        Factory.should_receive(:create).with('user', {'foo' => 'bar', 'baz' => 'bing bong'}).and_return(@user)
        do_create_model
      end
      
      describe "after create," do
        before { do_create_model }
        
        it_should_behave_like "after storing a single user"
      end
    end  

    describe "('an user: \"fred\")" do
      def do_create_model
        @session.create_model('an user: "fred"')
      end
  
      it "should call Factory.create('user', {})" do
        Factory.should_receive(:create).with('user', {}).and_return(@user)
        do_create_model
      end
      
      describe "after create," do
        before { do_create_model }
        
        it_should_behave_like "after storing a single user"
              
        it "original_model('the user: \"fred\"') should retrieve the user" do
          @session.original_model('the user: "fred"').should == @user
        end
      
        it "original_model('the user: \"shirl\"') should NOT retrieve the user" do
          @session.original_model('the user: "shirl"').should_not == @user
        end
      end
    end  
  end

  describe '#find_model' do
    before do
      @user = mock_model(User)
      User.stub!(:find).and_return(@user)
    end
    
    def do_find_model
      @session.find_model('a user', 'hair: "pink"')
    end
    
    it "should call User.find :first, :conditions => {'hair' => 'pink'}" do
      User.should_receive(:find).with(:first, :conditions => {'hair' => 'pink'}).and_return(@user)
      do_find_model
    end
    
    describe "after find," do
      before { do_find_model }
      
      it_should_behave_like "after storing a single user"
    end
  end
  
  describe 'creating \'a super admin: "fred"\', then \'a user: "shirl"\', \'then 1 super_admin\'' do
    before do
      @user = @fred = mock_model(User)
      @shirl  = mock_model(User)
      @noname = mock_model(User)
      Factory.stub!(:create).and_return(@fred, @shirl, @noname)
    end
    
    def do_create_users
      @session.create_model('a super admin: "fred"')
      @session.create_model('a user: "shirl"')
      @session.create_model('1 super_admin')
    end
    
    it "should call Factory.create with <'super_admin'>, <'user'>, <'super_admin'>" do
      Factory.should_receive(:create).with('super_admin', {}).twice
      Factory.should_receive(:create).with('user', {}).once
      do_create_users
    end
    
    describe "after create," do
      before do
        do_create_users
      end
      
      it "original_models('user') should == [@fred, @shirl, @noname]" do
        @session.original_models('user').should == [@fred, @shirl, @noname]
      end
      
      it "original_models('super_admin') should == [@fred, @noname]" do
        @session.original_models('super_admin').should == [@fred, @noname]
      end
      
      describe "#original_model" do
        it "'that user' should be @noname (the last user created - as super_admins are users)" do
          @session.original_model('that user').should == @noname
        end

        it "'the super admin' should be @noname (the last super admin created)" do
          @session.original_model('that super admin').should == @noname
        end
        
        it "'the 1st super admin' should be @fred" do
          @session.original_model('the 1st super admin').should == @fred
        end
        
        it "'the first user' should be @fred" do
          @session.original_model('the first user').should == @fred
        end
        
        it "'the 2nd user' should be @shirl" do
          @session.original_model('the 2nd user').should == @shirl
        end
        
        it "'the last user' should be @noname" do
          @session.original_model('the last user').should == @noname
        end
        
        it "'the user: \"fred\" should be @fred" do
          @session.original_model('the user: "fred"').should == @fred
        end
        
        it "'the user: \"shirl\" should be @shirl" do
          @session.original_model('the user: "shirl"').should == @shirl
        end
      end
    end
  end

  describe "when 'the user: \"me\"' exists" do
    before do
      @user = mock_model(User)
      User.stub!(:find).and_return(@user)
      Factory.stub!(:create).and_return(@user)
      @session.create_model('the user: "me"')
    end
  
    it 'model("I") should return the user' do
      @session.model('I').should == @user
    end

    it 'model("myself") should return the user' do
      @session.model('myself').should == @user
    end
    
    describe '#parse_fields' do
      it "'author: the user' should return {\"author\" => <user>}" do
        @session.parse_fields('author: the user').should == {"author" => @user}
      end

      it "'author: myself' should return {\"author\" => <user>}" do
        @session.parse_fields('author: myself').should == {"author" => @user}
      end
      
      it "'author: the user, approver: I, rating: \"5\"' should return {'author' => <user>, 'approver' => <user>, 'rating' => '5'}" do
        @session.parse_fields('author: the user, approver: I, rating: "5"').should == {'author' => @user, 'approver' => @user, 'rating' => '5'}
      end
    end
  end
end