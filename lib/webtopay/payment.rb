class WebToPay::Payment
  ATTRIBUTES = [:projectid, :orderid, :lang, :amount, :currency, :accepturl, :cancelurl, :callbackurl,
                :country, :paytext, :p_email, :p_name, :p_surname, :payment, :test, :version, :only_payments]
  UNDERSCORE_MAPPINGS = {pname: :p_name, pemail: :p_email, psurname: :p_surname, onlypayments: :only_payments}
  attr_accessor *ATTRIBUTES

  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  def initialize(params = {}, user_params = {})
    self.version = WebToPay::API_VERSION
    self.projectid = user_params[:projectid] || WebToPay.config.project_id
    @sign_password = user_params[:sign_password] || WebToPay.config.sign_password

    params.each_pair do |field, value|
      field_name = field.to_s.downcase.gsub('_', '').to_sym
      field_name = UNDERSCORE_MAPPINGS[field_name] || field_name
      self.public_send("#{field_name}=", value)
    end
  end

  def query
    @query ||= begin
      query = []
      ATTRIBUTES.each do |field|
        value = self.public_send(field)
        next if value.blank?
        query << "#{field}=#{ CGI::escape value.to_s}"
      end
      query.join('&')
    end
  end

  def data # encoded query
    @data ||= Base64.encode64(query).gsub("\n", '').gsub('/', '+').gsub('_', '-')
  end

  def url
    "https://www.mokejimai.lt/pay?data=#{CGI::escape data}&sign=#{CGI::escape sign}"
  end

  def sign
    Digest::MD5.hexdigest(data + @sign_password)
  end

  def to_key
  end
end