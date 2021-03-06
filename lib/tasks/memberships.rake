namespace :memberships do
  desc 'Update all current memberships cached basket counts'
  task update_baskets_counts: :environment do
    ACP.enter_each! do
      Membership.current_year.find_each(&:update_baskets_counts!)
      puts "#{Current.acp.name}: Memberships basket counts updated."
    end
  end

  desc 'Send open renewal reminders'
  task send_renewal_reminders: :environment do
    ACP.enter_each! do
      Membership.send_renewal_reminders!
    end
  end

  desc 'Ensure that membership.price cache is not out-of-sync'
  task check_price_cache: :environment do
    MembershipPriceCacheError = Class.new(StandardError)
    ACP.enter_each! do
      Membership.current_year.find_each do |m|
        expected_price =
          m.basket_sizes_price +
          m.baskets_annual_price_change +
          m.basket_complements_price +
          m.basket_complements_annual_price_change +
          m.depots_price +
          m.activity_participations_annual_price_change
        if m.price != expected_price
          p "#{Current.acp.name}: Membership #{m.id} (#{m.member.name})"
          ExceptionNotifier.notify(MembershipPriceCacheError,
            membership_id: m.id,
            price: m.price,
            expected_price: expected_price,
            baskets_annual_price_change: m.baskets_annual_price_change,
            basket_sizes_price: m.basket_sizes_price,
            basket_complements_price: m.basket_complements_price,
            basket_complements_annual_price_change: m.basket_complements_annual_price_change,
            depots_price: m.depots_price,
            activity_participations_annual_price_change: m.activity_participations_annual_price_change)
          m.send(:update_price_and_invoices_amount!)
        end
      end
    end
  end
end
