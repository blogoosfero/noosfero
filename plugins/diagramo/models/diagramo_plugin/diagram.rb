require 'php_serialize'
require 'mechanize'

class DiagramoPlugin::Diagram < Article

  settings_items :diagramo_id

  before_create :diagramo_create

  def self.short_description
    "Diagrama"
  end

  def self.description
    "Construa um diagrama com o Diagramo"
  end

  def to_html options = {}
    lambda do
      render 'content_viewer/diagramo_plugin/diagram'
    end
  end

  def author?
    self.user and self.user.id == self.author_id
  end

  def diagramo_uri
    if self.author?
      "#{EditorUrl}?diagramId=#{self.diagramo_id}&biscuit=#{diagramo_cookie}"
    else
      "#{ViewDiagramUrl}?diagramId=#{self.diagramo_id}"
    end
  end

  def user
    @user ||= User.current.person rescue nil
  end

  def diagramo_email
    "#{self.user.identifier}@#{self.profile.environment.default_hostname}"
  end
  def diagramo_password
    Digest::MD5.hexdigest self.user.identifier
  end

  protected

  # move to config file
  BaseUrl = "http://diagramas.blogoosfero.cc"
  AdminEmail = 'admindiagramo@blogoosfero.cc'
  AdminPassword = 'admindodiagramo'

  ControllerUrl = "#{BaseUrl}/editor/common/controller.php"
  EditorUrl = "#{BaseUrl}/editor/editor.php"
  ViewDiagramUrl = "#{BaseUrl}/editor/viewDiagram.php"
  LoginUrl = "#{BaseUrl}/editor/login.php"

  def diagramo_login
    self.mech.post ControllerUrl, :action => 'loginExe', :email => diagramo_email, :password => diagramo_password
  end
  def diagramo_logout
    self.mech.post ControllerUrl, :action => 'logoutExe'
  end

  def diagramo_user_exists?
    self.diagramo_logout
    page = self.diagramo_login
    page.uri.to_s != LoginUrl
  end

  def mech
    @mech ||= Mechanize.new
  end

  def diagramo_create_user
    page = self.mech.post ControllerUrl, :action => 'loginExe', :email => AdminEmail, :password => AdminPassword
    page = self.mech.post ControllerUrl, :action => 'addUserExe', :email => diagramo_email, :password => diagramo_password
    # logout admin
    self.diagramo_logout
    self.diagramo_login
  end

  def diagramo_create
    return if self.diagramo_id.present?

    self.diagramo_create_user unless self.diagramo_user_exists?
    page = self.mech.post ControllerUrl, :action => 'firstSaveExe', :public => 'true', :title => self.title, :description => self.body
    page.uri.to_s =~ /diagramId=(.*)$/
    self.diagramo_id = $1
  end

  def diagramo_cookie
    biscuit = PHP.serialize({:email => diagramo_email, :password => Digest::MD5.hexdigest(diagramo_password)})
    biscuit = strict_encode64 biscuit
    biscuit = biscuit.reverse
    biscuit = uuencode biscuit
    biscuit = strict_encode64 biscuit
  end

  # for ruby 1.8
  def strict_encode64 str
    Base64.encode64(str).gsub(/\n/, '')
  end
  def uuencode str
    [str].pack('u') + "`\n"
  end

end
