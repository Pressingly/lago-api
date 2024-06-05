# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConsumptionEvent::EmitService, type: :service do
  subject(:emit_service) { described_class.new(payload: payload, client: client) }
end
