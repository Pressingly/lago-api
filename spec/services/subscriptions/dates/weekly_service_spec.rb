# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscriptions::Dates::WeeklyService, type: :service do
  subject(:date_service) { described_class.new(subscription, billing_date, false) }

  let(:subscription) do
    create(
      :subscription,
      plan: plan,
      subscription_date: subscription_date,
      billing_time: billing_time,
      started_at: started_at,
    )
  end

  let(:plan) { create(:plan, interval: :weekly, pay_in_advance: pay_in_advance) }
  let(:pay_in_advance) { false }

  let(:subscription_date) { DateTime.parse('02 Feb 2021') }
  let(:billing_date) { DateTime.parse('07 Mar 2022') }
  let(:started_at) { subscription_date }

  describe 'from_date' do
    let(:result) { date_service.from_date.to_s }

    context 'when billing_time is calendar' do
      let(:billing_time) { :calendar }

      it 'returns the beginning of the previous week' do
        expect(result).to eq('2022-02-28')
        expect(Time.zone.parse(result).wday).to eq(1)
      end

      context 'when date is before the start date' do
        let(:started_at) { DateTime.parse('01 Mar 2022') }

        it 'returns the start date' do
          expect(result).to eq(started_at.to_date.to_s)
        end
      end

      context 'when subscription is just terminated' do
        let(:billing_date) { DateTime.parse('10 Mar 2022') }

        before { subscription.terminated! }

        it 'returns the beginning of the week' do
          expect(result).to eq('2022-03-07')
          expect(Time.zone.parse(result).wday).to eq(1)
        end

        context 'when plan is pay in advance' do
          let(:pay_in_advance) { true }

          it 'returns the beginning of the current week' do
            expect(result).to eq('2022-03-07')
            expect(Time.zone.parse(result).wday).to eq(1)
          end
        end
      end
    end

    context 'when billing_time is anniversary' do
      let(:billing_time) { :anniversary }
      let(:billing_date) { DateTime.parse('10 Mar 2022') }

      it 'returns the previous week week day' do
        expect(result).to eq('2022-03-01')
        expect(Time.zone.parse(result).wday).to eq(subscription_date.wday)
      end

      context 'when date is before the start date' do
        let(:started_at) { DateTime.parse('08 Mar 2022') }

        it 'returns the start date' do
          expect(result).to eq(started_at.to_date.to_s)
          expect(Time.zone.parse(result).wday).to eq(subscription_date.wday)
        end
      end

      context 'when subscription is just terminated' do
        before { subscription.terminated! }

        it 'returns the previous week day' do
          expect(result).to eq('2022-03-08')
          expect(Time.zone.parse(result).wday).to eq(subscription_date.wday)
        end

        context 'when plan is pay in advance' do
          let(:pay_in_advance) { true }

          it 'returns the current week week day' do
            expect(result).to eq('2022-03-08')
            expect(Time.zone.parse(result).wday).to eq(subscription_date.wday)
          end
        end
      end
    end
  end

  describe 'to_date' do
    let(:result) { date_service.to_date.to_s }

    context 'when billing_time is calendar' do
      let(:billing_time) { :calendar }
      let(:billing_date) { DateTime.parse('07 Mar 2022') }

      it 'returns the end of the previous week' do
        expect(result).to eq('2022-03-06')
      end

      context 'when plan is pay in advance' do
        before { plan.update!(pay_in_advance: true) }

        it 'returns the end of the week' do
          expect(result).to eq('2022-03-13')
          expect(Time.zone.parse(result).wday).to eq(0)
        end
      end

      context 'when subscription is just terminated' do
        let(:billing_date) { DateTime.parse('07 Mar 2022') }
        let(:terminated_at) { DateTime.parse('02 Mar 2022') }

        before do
          subscription.update!(
            status: :terminated,
            terminated_at: terminated_at,
          )
        end

        it 'returns the termination date' do
          expect(result).to eq(subscription.terminated_at.to_date.to_s)
        end
      end
    end

    context 'when billing_time is anniversary' do
      let(:billing_time) { :anniversary }
      let(:billing_date) { DateTime.parse('10 Mar 2022') }

      it 'returns the previous week week day' do
        expect(result).to eq('2022-03-07')
      end

      context 'when plan is pay in advance' do
        before { plan.update!(pay_in_advance: true) }

        it 'returns the end of the current period' do
          expect(result).to eq('2022-03-14')
        end
      end

      context 'when subscription is just terminated' do
        before do
          subscription.update!(
            status: :terminated,
            terminated_at: DateTime.parse('02 Mar 2022'),
          )
        end

        it 'returns the termination date' do
          expect(result).to eq(subscription.terminated_at.to_date.to_s)
        end
      end
    end
  end

  describe 'charges_from_date' do
    let(:result) { date_service.charges_from_date.to_s }

    context 'when billing_time is calendar' do
      let(:billing_time) { :calendar }

      it 'returns from_date' do
        expect(result).to eq(date_service.from_date.to_s)
      end

      context 'when subscription started in the middle of a period' do
        let(:started_at) { DateTime.parse('03 Mar 2022') }

        it 'returns the start date' do
          expect(result).to eq(subscription.started_at.to_date.to_s)
        end
      end

      context 'when plan is pay in advance' do
        let(:pay_in_advance) { true }

        it 'returns the start of the previous period' do
          expect(result).to eq((date_service.from_date - 1.week).to_s)
        end
      end
    end

    context 'when billing_time is anniversary' do
      let(:billing_time) { :anniversary }
      let(:billing_date) { DateTime.parse('10 Mar 2022') }

      it 'returns from_date' do
        expect(result).to eq(date_service.from_date.to_s)
      end

      context 'when subscription started in the middle of a period' do
        let(:started_at) { DateTime.parse('03 Mar 2022') }

        it 'returns the start date' do
          expect(result).to eq(subscription.started_at.to_date.to_s)
        end
      end

      context 'when plan is pay in advance' do
        let(:pay_in_advance) { true }

        it 'returns the start of the previous period' do
          expect(result).to eq((date_service.from_date - 1.week).to_s)
        end
      end
    end
  end

  describe 'charges_to_date' do
    let(:result) { date_service.charges_to_date.to_s }

    context 'when billing_time is calendar' do
      let(:billing_time) { :calendar }

      it 'returns to_date' do
        expect(result).to eq(date_service.to_date.to_s)
      end

      context 'when subscription is terminated in the middle of a period' do
        let(:terminated_at) { DateTime.parse('06 Mar 2022') }

        before do
          subscription.update!(status: :terminated, terminated_at: terminated_at)
        end

        it 'returns the terminated date' do
          expect(result).to eq(subscription.terminated_at.to_date.to_s)
        end
      end

      context 'when plan is pay in advance' do
        let(:pay_in_advance) { true }

        it 'returns the end of the previous period' do
          expect(result).to eq((date_service.from_date - 1.day).to_s)
        end
      end
    end

    context 'when billing_time is anniversary' do
      let(:billing_time) { :anniversary }
      let(:billing_date) { DateTime.parse('10 Mar 2022') }

      it 'returns to_date' do
        expect(result).to eq(date_service.to_date.to_s)
      end

      context 'when subscription is terminated in the middle of a period' do
        let(:terminated_at) { DateTime.parse('06 Mar 2022') }

        before do
          subscription.update!(status: :terminated, terminated_at: terminated_at)
        end

        it 'returns the terminated date' do
          expect(result).to eq(subscription.terminated_at.to_date.to_s)
        end
      end

      context 'when plan is pay in advance' do
        let(:pay_in_advance) { true }

        it 'returns the end of the previous period' do
          expect(result).to eq((date_service.from_date - 1.day).to_s)
        end
      end
    end
  end

  describe 'next_end_of_period' do
    let(:result) { date_service.next_end_of_period(billing_date.to_date).to_s }

    context 'when billing_time is calendar' do
      let(:billing_time) { :calendar }

      it 'returns the last day of the week' do
        expect(result).to eq('2022-03-13')
      end
    end

    context 'when billing_time is anniversary' do
      let(:billing_time) { :anniversary }
      let(:billing_date) { DateTime.parse('08 Mar 2022') }

      it 'returns the end of the billing week' do
        expect(result).to eq('2022-03-14')
      end

      context 'when date is the end of the period' do
        let(:billing_date) { DateTime.parse('07 Mar 2022') }

        it 'returns the date' do
          expect(result).to eq(billing_date.to_date.to_s)
        end
      end
    end
  end

  describe 'compute_previous_beginning_of_period' do
    let(:result) { date_service.previous_beginning_of_period(current_period: current_period).to_s }

    let(:current_period) { false }

    context 'when billing_time is calendar' do
      let(:billing_time) { :calendar }

      it 'returns the first day of the previous week' do
        expect(result).to eq('2022-02-28')
      end

      context 'with current period argument' do
        let(:current_period) { true }

        it 'returns the first day of the week' do
          expect(result).to eq('2022-03-07')
        end
      end
    end

    context 'when billing_time is anniversary' do
      let(:billing_time) { :anniversary }

      it 'returns the beginning of the previous period' do
        expect(result).to eq('2022-02-22')
      end

      context 'with current period argument' do
        let(:current_period) { true }

        it 'returns the beginning of the current period' do
          expect(result).to eq('2022-03-01')
        end
      end
    end
  end

  describe 'single_day_price' do
    let(:billing_time) { :anniversary }
    let(:billing_date) { DateTime.parse('08 Mar 2022') }
    let(:result) { date_service.single_day_price }

    it 'returns the price of single day' do
      expect(result).to eq(plan.amount_cents.fdiv(7))
    end
  end
end