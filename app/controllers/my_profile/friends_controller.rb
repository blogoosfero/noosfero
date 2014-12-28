class FriendsController < MyProfileController
  
  protect 'manage_friends', :profile
  
  def index
    if is_cache_expired?(profile.manage_friends_cache_key(params))
      @friends = profile.friends.paginate(:per_page => per_page, :page => params[:npage])
    end
  end

  def remove
    @friend = profile.friends.find(params[:id])
    if request.post? && params[:confirmation]
      Friendship.remove_friendship(profile, @friend)
      redirect_to :action => 'index'
    end
  end

  protected

  class << self
    def per_page
      12
    end
  end
  def per_page
    self.class.per_page
  end

end
