module MembersHelper
  def link_with_session(member, session)
    link = auto_link(member)
    link += " (#{session.email})" if session&.email
    link
  end

  def languages_collection
    Current.acp.languages.map { |l| [t("languages.#{l}"), l] }
  end

  def billing_year_divisions_collection
    Current.acp.billing_year_divisions.map { |i|
      [I18n.t("billing.year_division.x#{i}"), i]
    }
  end

  def basket_sizes_collection(no_basket_option: true)
    col = BasketSize.all.map { |bs|
      [
        collection_text(bs.name,
          price: basket_size_price_info(bs.price),
          details: [
            deliveries_count(deliveries_counts),
            activities_count(bs.activity_participations_demanded_annualy),
            acp_shares_number(bs.acp_shares_number)
          ].compact.join(', ')),
        bs.id
      ]
    }
    if no_basket_option
      col << [
        collection_text(t('helpers.no_basket_size'),
          details:
            if Current.acp.annual_fee
              t('helpers.no_basket_size_annual_fee')
            elsif Current.acp.share?
              t('helpers.no_basket_size_acp_share')
            end
        ),
        0
      ]
    end
    col
  end

  def basket_prices_extra_collection
    [
      [0.0, 20],
      [1.0, 21],
      [2.0, 22],
      [4.0, 24],
      [8.0, 28]
    ].map { |(extra, hours)|
      details = "salaire jardinier ~#{hours}.- net/h, ~#{hours * 100}.- net/m à 50%"
      [
        if extra.zero?
          collection_text('Tarif de base', details: details)
        else
          collection_text("+ #{extra.to_i}.-/panier",
            price: basket_size_price_info(extra),
            details: details)
        end,
        extra
      ]
    }
  end

  def basket_complements_collection
    BasketComplement
      .visible
      .select { |bc| bc.deliveries_count.positive? }
      .map { |bc|
        [
          collection_text(bc.name,
            price: price_info(bc.annual_price, precision: 2),
            details: deliveries_count(bc.deliveries_count)),
          bc.id
        ]
      }
  end

  def depots_collection(membership = nil)
    visible_depots(membership).map { |d|
      details = []
      details << deliveries_count(d.deliveries_count) if deliveries_counts.many?
      if address = d.full_address
        details << address + map_icon(address).html_safe
      elsif d.address.present?
        details << d.address
      end
      [
        collection_text(d.form_name || d.name,
          price: price_info(d.annual_price, precision: 0),
          details: details.compact.join(', ')),
        d.id
      ]
    }
  end

  def terms_of_service_label
    if Current.acp.statutes_url
      t('.terms_of_service_with_statutes',
        terms_url: Current.acp.terms_of_service_url,
        statutes_url: Current.acp.statutes_url).html_safe
    else
      t('.terms_of_service',
        terms_url: Current.acp.terms_of_service_url).html_safe
    end
  end

  def diplay_address(member)
    parts = [
      member.address,
      "#{member.zip} #{member.city}"
    ].join("</br>").html_safe
  end

  def display_emails(member)
    emails = member.emails_array - [current_session.email]
    parts = [content_tag(:i, current_session.email)]
    parts += emails
    parts.join(', ').html_safe
  end

  def display_phones(member)
    member.phones_array.map(&:phony_formatted).join(', ')
  end

  private

  def visible_depots(membership = nil)
    depot_ids = Depot.visible.pluck(:id)
    depot_ids << membership.depot_id if membership
    Depot.where(id: depot_ids.uniq).order('form_priority, price, name').to_a
  end

  def deliveries_counts
    @deliveries_counts ||= visible_depots.map(&:deliveries_count).uniq.sort
  end

  def price_info(price, *options)
    number_to_currency(price.round_to_five_cents, *options) if price.positive?
  end

  def basket_size_price_info(price)
    if deliveries_counts.many?
      [
        price_info(deliveries_counts.min * price, precision: 0),
        price_info(deliveries_counts.max * price, precision: 0, format: '%n')
      ].join('-')
    else
      price_info(deliveries_counts.first.to_i * price, precision: 0)
    end
  end

  def collection_text(text, price: nil, details: nil)
    txts = [text]
    txts << "<em class='price'>#{price}</em>" if price
    txts << "<em>(#{details})</em>" if details.present?
    txts.join.html_safe
  end

  def map_icon(location)
    link_to "https://www.google.com/maps?q=#{location}", title: location, target: :blank, class: 'map_link' do
      inline_svg_pack_tag 'media/images/members/map_signs.svg', size: '16px'
    end
  end

  def deliveries_count(counts)
    case counts
    when Array
      if counts.many?
        "#{counts.min}-#{counts.max}&nbsp;#{Delivery.model_name.human(count: counts.max)}".downcase
      else
        count = counts.first.to_i
        "#{count}&nbsp;#{Delivery.model_name.human(count: count)}".downcase
      end
    when Integer
      "#{counts}&nbsp;#{Delivery.model_name.human(count: counts)}".downcase
    end
  end

  def activities_count(count)
    return unless Current.acp.feature?('activity')

    t_activity('helpers.activities_count_per_year', count: count).gsub(/\s/, '&nbsp;')
  end

  def acp_shares_number(number)
    return unless number

    t('helpers.acp_shares_number', count: number)
  end
end
