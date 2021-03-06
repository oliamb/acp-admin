class AdminMailer < ApplicationMailer
  def depot_delivery_list_email
    depot = params[:depot]
    baskets = params[:baskets]
    delivery = params[:delivery]
    I18n.with_locale(depot.language) do
      xlsx = XLSX::Delivery.new(delivery, depot)
      attachments[xlsx.filename] = {
        mime_type: xlsx.content_type,
        content: xlsx.data
      }
      pdf = PDF::Delivery.new(delivery, depot)
      attachments[pdf.filename] = {
        mime_type: pdf.content_type,
        content: pdf.render
      }
      content = liquid_template.render(
        'depot' => Liquid::DepotDrop.new(depot),
        'baskets' => baskets.map { |b| Liquid::BasketDrop.new(b) },
        'delivery' => Liquid::DeliveryDrop.new(delivery))
      content_mail(content,
        to: depot.emails_array,
        subject: t('.subject',
          date: I18n.l(delivery.date),
          depot: depot.name))
    end
  end

  def invitation_email
    admin = params[:admin]
    I18n.with_locale(admin.language) do
      content = liquid_template.render(
        'acp' => Liquid::ACPDrop.new(Current.acp),
        'admin' => Liquid::AdminDrop.new(admin),
        'action_url' => params[:action_url])
      content_mail(content,
        to: admin.email,
        subject: t('.subject', acp: Current.acp.name))
    end
  end

  def invoice_overpaid_email
    @admin = params[:admin]
    I18n.with_locale(@admin.language) do
      invoice = Liquid::InvoiceDrop.new(params[:invoice])
      content = liquid_template.render(
        'admin' => Liquid::AdminDrop.new(@admin),
        'member' => Liquid::AdminMemberDrop.new(params[:member]),
        'invoice' => invoice)
      content_mail(content,
        to: @admin.email,
        subject: t('.subject', number: invoice.number))
    end
  end

  def new_absence_email
    @admin = params[:admin]
    I18n.with_locale(@admin.language) do
      content = liquid_template.render(
        'admin' => Liquid::AdminDrop.new(@admin),
        'member' => Liquid::AdminMemberDrop.new(params[:member]),
        'absence' => Liquid::AbsenceDrop.new(params[:absence]))
      content_mail(content,
        to: @admin.email,
        subject: t('.subject'))
    end
  end

  def new_email_suppression_email
    @admin = params[:admin]
    @email_suppression = params[:email_suppression]
    I18n.with_locale(@admin.language) do
      content = liquid_template.render(
        'admin' => Liquid::AdminDrop.new(@admin),
        'email_suppression' => Liquid::EmailSuppressionDrop.new(@email_suppression))
      content_mail(content,
        to: @admin.email,
        subject: t('.subject', reason: @email_suppression.reason))
    end
  end

  def new_inscription_email
    @admin = params[:admin]
    I18n.with_locale(@admin.language) do
      content = liquid_template.render(
        'admin' => Liquid::AdminDrop.new(@admin),
        'member' => Liquid::AdminMemberDrop.new(params[:member]))
      content_mail(content,
        to: @admin.email,
        subject: t('.subject'))
    end
  end

  def new_group_buying_order_email
    @admin = params[:admin]
    @order = params[:order]
    I18n.with_locale(@admin.language) do
      content = liquid_template.render(
        'admin' => Liquid::AdminDrop.new(@admin),
        'order' => Liquid::GroupBuyingOrderDrop.new(@order))
      content_mail(content,
        to: @admin.email,
        subject: t('.subject', order_id: @order.id))
    end
  end
end
