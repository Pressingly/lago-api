module Authorization
  class AuthorizeValidator
    include ActiveModel::Model

    attr_accessor :external_customer_id, :publisher_id, :action_name, :context, :resource, :timestamp

    validates :external_customer_id, :publisher_id, :action_name, :timestamp, presence: true

    validate :resource_validations
    def initialize(params)
      @external_customer_id = params[:externalCustomerId]
      @publisher_id = params[:publisherId]
      @action_name = params[:actionName]
      @context = params[:context]
      @resource = params[:resource]
      @timestamp = params[:timestamp]
    end

    def resource_validations
      if @resource.blank? || @resource['id'].blank? || @resource['type'].blank?
        errors.add(:resource, 'Resource id and type are required')
      end
    end
  end
end
