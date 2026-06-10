# frozen_string_literal: true

require "securerandom"

module SatuRayaUi
  module UI
    # UI Contract: Definisi murni properti komponen (❌ depend apa pun)
    module Contract
      class Button
        attr_reader :label, :path, :method, :variant, :target, :aria_label, :class_name, :data

        def initialize(label:, path:, method: :get, variant: :primary, target: nil, aria_label: nil, class_name: nil, data: {})
          @label = label
          @path = path
          @method = method
          @variant = variant
          @target = target
          @aria_label = aria_label || label
          @class_name = class_name
          @data = data
        end
      end

      class Modal
        attr_reader :title, :id, :class_name, :size

        def initialize(title:, id: nil, class_name: nil, size: :md)
          @title = title
          @id = id || "modal-#{SecureRandom.hex(4)}"
          @class_name = class_name
          @size = size
        end
      end

      class Dropdown
        attr_reader :label, :id, :class_name, :variant

        def initialize(label:, id: nil, class_name: nil, variant: :outline)
          @label = label
          @id = id || "dropdown-#{SecureRandom.hex(4)}"
          @class_name = class_name
          @variant = variant
        end
      end

      class Flash
        attr_reader :type, :message, :id

        def initialize(type:, message:, id: nil)
          @type = type.to_sym
          @message = message
          @id = id || "flash-#{SecureRandom.hex(4)}"
        end
      end

      class Card
        attr_reader :rounded, :padding, :hover, :class_name

        def initialize(rounded: "3xl", padding: "6", hover: false, class_name: nil)
          @rounded = rounded
          @padding = padding
          @hover = hover
          @class_name = class_name
        end
      end

      class Pagination
        attr_reader :current_page, :total_pages, :total_count, :per_page, :base_url

        def initialize(current_page:, total_pages:, total_count:, per_page: 20, base_url: nil)
          @current_page = current_page.to_i
          @total_pages = total_pages.to_i
          @total_count = total_count.to_i
          @per_page = per_page.to_i
          @base_url = base_url
        end

        def prev_page
          current_page > 1 ? current_page - 1 : nil
        end

        def next_page
          current_page < total_pages ? current_page + 1 : nil
        end
      end

      class Table
        attr_reader :headers, :class_name

        def initialize(headers: [], class_name: nil)
          @headers = headers
          @class_name = class_name
        end
      end

      class Badge
        attr_reader :label, :color, :size, :class_name

        def initialize(label:, color: :slate, size: :md, class_name: nil)
          @label = label
          @color = color.to_sym
          @size = size.to_sym
          @class_name = class_name
        end
      end

      class FormField
        attr_reader :name, :label, :required, :hint, :class_name

        def initialize(name:, label:, required: false, hint: nil, class_name: nil)
          @name = name
          @label = label
          @required = required
          @hint = hint
          @class_name = class_name
        end
      end

      class FormInput
        attr_reader :form, :field, :type, :placeholder, :prefix, :rows, :class_name, :data, :errors

        def initialize(form:, field:, type: :text, placeholder: nil, prefix: nil, rows: 4, class_name: nil, data: {}, errors: [])
          @form = form
          @field = field
          @type = type.to_sym
          @placeholder = placeholder
          @prefix = prefix
          @rows = rows
          @class_name = class_name
          @data = data
          @errors = Array(errors)
        end

        def has_errors?
          errors.any? || (form&.object&.errors&.include?(field) if form&.object.respond_to?(:errors))
        end

        def error_messages
          return errors if errors.any?
          form&.object&.errors&.full_messages_for(field) || []
        end
      end
    end

    # Base UI: Logika komponen (depend: UI Contract)
    module Base
      class Button
        def initialize(contract)
          @contract = contract
        end

        def render_as_button?
          @contract.method.present? && @contract.method.to_sym != :get
        end

        def attributes
          {
            aria: { label: @contract.aria_label },
            data: @contract.data,
            target: @contract.target
          }
        end
      end

      class Modal
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {
            id: @contract.id,
            role: "dialog",
            aria: { modal: true, labelledby: "#{@contract.id}-title" }
          }
        end
      end

      class Dropdown
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {
            id: @contract.id,
            "data-controller": "dropdown",
            "data-action": "click->dropdown#toggle click@window->dropdown#close"
          }
        end
      end

      class Flash
        def initialize(contract)
          @contract = contract
        end

        def icon_name
          case @contract.type
          when :success then "check-circle"
          when :alert, :danger then "exclamation-circle"
          when :warning then "exclamation-triangle"
          else "information-circle"
          end
        end
      end

      class Card
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {}
        end
      end

      class Pagination
        def initialize(contract)
          @contract = contract
        end

        def page_url(page)
          return "#" unless @contract.base_url
          separator = @contract.base_url.include?("?") ? "&" : "?"
          "#{@contract.base_url}#{separator}page=#{page}"
        end
      end

      class Table
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {}
        end
      end

      class Badge
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {}
        end
      end

      class FormField
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {}
        end
      end

      class FormInput
        def initialize(contract)
          @contract = contract
        end

        def attributes
          {}
        end
      end
    end

    # Tailwind: Definisi style murni (❌ depend apa pun)
    module Tailwind
      BUTTON_BASE = "inline-flex items-center justify-center rounded-xl px-4 py-2 text-sm font-bold shadow-sm transition active:scale-[0.98]"
      
      BUTTON_VARIANTS = {
        primary: "bg-indigo-600 text-white hover:bg-indigo-700",
        secondary: "bg-white border border-slate-200 text-slate-700 hover:border-indigo-200 hover:text-indigo-700",
        danger: "bg-rose-600 text-white hover:bg-rose-700",
        outline: "border border-slate-200 bg-white text-slate-700 hover:border-indigo-200 hover:text-indigo-700"
      }

      MODAL_BACKDROP = "fixed inset-0 bg-slate-900/50 backdrop-blur-sm transition-opacity"
      MODAL_CONTAINER = "fixed inset-0 z-50 flex items-center justify-center p-4 overflow-y-auto"
      MODAL_CONTENT = "bg-white rounded-2xl shadow-xl transform transition-all w-full"
      MODAL_SIZES = {
        sm: "max-w-md",
        md: "max-w-lg",
        lg: "max-w-2xl",
        xl: "max-w-4xl",
        full: "max-w-full m-4"
      }

      FLASH_BASE = "flex items-center p-4 rounded-xl border mb-4 animate-in fade-in slide-in-from-top-4"
      FLASH_VARIANTS = {
        success: "bg-emerald-50 border-emerald-100 text-emerald-800",
        notice: "bg-blue-50 border-blue-100 text-blue-800",
        alert: "bg-rose-50 border-rose-100 text-rose-800",
        warning: "bg-amber-50 border-amber-100 text-amber-800"
      }

      CARD_BASE = "bg-white border border-slate-100 shadow-sm"
      CARD_HOVER = "transition-all hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/70"

      PAGINATION_CONTAINER = "flex items-center justify-between border-t border-slate-100 px-4 py-3 sm:px-6"
      PAGINATION_ITEM_BASE = "relative inline-flex items-center px-4 py-2 text-sm font-medium transition"
      PAGINATION_ITEM_ACTIVE = "z-10 bg-indigo-600 text-white rounded-lg"
      PAGINATION_ITEM_INACTIVE = "text-slate-500 hover:bg-slate-50 rounded-lg"

      TABLE_CONTAINER = "overflow-x-auto rounded-2xl border border-slate-100"
      TABLE_BASE = "min-w-full divide-y divide-slate-100"
      TABLE_THEAD = "bg-slate-50/50"
      TABLE_TH = "px-6 py-4 text-left text-xs font-bold uppercase tracking-wider text-slate-500"
      TABLE_TD = "px-6 py-4 text-sm text-slate-600 whitespace-nowrap"
      TABLE_TR_HOVER = "hover:bg-slate-50/50 transition"

      DROPDOWN_MENU = "absolute right-0 z-50 mt-2 w-56 origin-top-right rounded-xl bg-white shadow-lg ring-1 ring-slate-200 focus:outline-none hidden"
      DROPDOWN_ITEM = "block px-4 py-2 text-sm text-slate-700 hover:bg-slate-50 transition first:rounded-t-xl last:rounded-b-xl"

      BADGE_BASE = "inline-flex items-center rounded-full font-black uppercase tracking-wider ring-1 ring-inset"
      BADGE_COLORS = {
        amber: "bg-amber-50 text-amber-700 ring-amber-200",
        blue: "bg-blue-50 text-blue-700 ring-blue-200",
        emerald: "bg-emerald-50 text-emerald-700 ring-emerald-200",
        indigo: "bg-indigo-50 text-indigo-700 ring-indigo-200",
        rose: "bg-rose-50 text-rose-700 ring-rose-200",
        slate: "bg-slate-50 text-slate-700 ring-slate-200"
      }
      BADGE_SIZES = {
        sm: "px-2 py-0.5 text-[10px]",
        md: "px-2.5 py-1 text-xs"
      }

      FORM_FIELD_WRAPPER = "space-y-2"
      FORM_LABEL = "block text-sm font-black text-slate-700"
      FORM_HINT = "text-xs font-semibold leading-5 text-slate-500"
      
      INPUT_BASE = "block w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-900 shadow-sm transition-colors placeholder:text-slate-400 focus:border-indigo-500 focus:outline-none focus:ring-4 focus:ring-indigo-100"
      INPUT_ERROR = "border-rose-300 text-rose-900 placeholder:text-rose-300 focus:border-rose-500 focus:ring-rose-100"
      INPUT_PREFIX_WRAPPER = "pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-sm font-black text-slate-400"
      
      ERROR_TEXT = "mt-2 text-xs font-bold text-rose-600 animate-in fade-in slide-in-from-top-1"
    end

    # Skins: Penggabungan (depend: Base UI + Tailwind + Contract)
    module Skins
      class Button
        def initialize(contract)
          @contract = contract
          @base = Base::Button.new(contract)
        end

        def classes
          [
            Tailwind::BUTTON_BASE,
            Tailwind::BUTTON_VARIANTS[@contract.variant.to_sym] || Tailwind::BUTTON_VARIANTS[:primary],
            @contract.class_name
          ].compact.join(" ")
        end

        def render_attributes
          @base.attributes.merge(class: classes)
        end
      end

      class Modal
        def initialize(contract)
          @contract = contract
          @base = Base::Modal.new(contract)
        end

        def content_classes
          [
            Tailwind::MODAL_CONTENT,
            Tailwind::MODAL_SIZES[@contract.size.to_sym] || Tailwind::MODAL_SIZES[:md],
            @contract.class_name
          ].compact.join(" ")
        end

        def backdrop_classes
          Tailwind::MODAL_BACKDROP
        end

        def container_classes
          Tailwind::MODAL_CONTAINER
        end

        def render_attributes
          @base.attributes
        end
      end

      class Flash
        def initialize(contract)
          @contract = contract
          @base = Base::Flash.new(contract)
        end

        def classes
          [
            Tailwind::FLASH_BASE,
            Tailwind::FLASH_VARIANTS[@contract.type] || Tailwind::FLASH_VARIANTS[:notice]
          ].compact.join(" ")
        end

        def icon_classes
          "h-5 w-5 mr-3 flex-shrink-0"
        end
      end

      class Card
        def initialize(contract)
          @contract = contract
          @base = Base::Card.new(contract)
        end

        def classes
          [
            Tailwind::CARD_BASE,
            "rounded-#{@contract.rounded}",
            "p-#{@contract.padding}",
            (Tailwind::CARD_HOVER if @contract.hover),
            @contract.class_name
          ].compact.join(" ")
        end

        def render_attributes
          @base.attributes.merge(class: classes)
        end
      end

      class Dropdown
        def initialize(contract)
          @contract = contract
          @base = Base::Dropdown.new(contract)
          @button_contract = Contract::Button.new(
            label: contract.label,
            path: "#",
            variant: contract.variant,
            class_name: "dropdown-trigger"
          )
          @button_skin = Skins::Button.new(@button_contract)
        end

        def button_classes
          @button_skin.classes
        end

        def menu_classes
          [Tailwind::DROPDOWN_MENU, @contract.class_name].compact.join(" ")
        end

        def item_classes
          Tailwind::DROPDOWN_ITEM
        end

        def render_attributes
          @base.attributes
        end
      end

      class Pagination
        def initialize(contract)
          @contract = contract
          @base = Base::Pagination.new(contract)
        end

        def container_classes
          Tailwind::PAGINATION_CONTAINER
        end

        def item_classes(page)
          [
            Tailwind::PAGINATION_ITEM_BASE,
            (page.to_i == @contract.current_page ? Tailwind::PAGINATION_ITEM_ACTIVE : Tailwind::PAGINATION_ITEM_INACTIVE)
          ].join(" ")
        end

        def page_url(page)
          @base.page_url(page)
        end
      end

      class Table
        def initialize(contract)
          @contract = contract
          @base = Base::Table.new(contract)
        end

        def container_classes
          Tailwind::TABLE_CONTAINER
        end

        def table_classes
          [Tailwind::TABLE_BASE, @contract.class_name].compact.join(" ")
        end

        def thead_classes
          Tailwind::TABLE_THEAD
        end

        def th_classes
          Tailwind::TABLE_TH
        end

        def td_classes
          Tailwind::TABLE_TD
        end

        def tr_classes
          Tailwind::TABLE_TR_HOVER
        end
      end

      class Badge
        def initialize(contract)
          @contract = contract
          @base = Base::Badge.new(contract)
        end

        def classes
          [
            Tailwind::BADGE_BASE,
            Tailwind::BADGE_COLORS[@contract.color] || Tailwind::BADGE_COLORS[:slate],
            Tailwind::BADGE_SIZES[@contract.size] || Tailwind::BADGE_SIZES[:md],
            @contract.class_name
          ].compact.join(" ")
        end

        def render_attributes
          @base.attributes.merge(class: classes)
        end
      end

      class FormField
        def initialize(contract)
          @contract = contract
          @base = Base::FormField.new(contract)
        end

        def wrapper_classes
          [Tailwind::FORM_FIELD_WRAPPER, @contract.class_name].compact.join(" ")
        end

        def label_classes
          Tailwind::FORM_LABEL
        end

        def hint_classes
          Tailwind::FORM_HINT
        end

        def render_attributes
          @base.attributes
        end
      end

      class FormInput
        def initialize(contract)
          @contract = contract
          @base = Base::FormInput.new(contract)
        end

        def input_classes
          [
            Tailwind::INPUT_BASE,
            (Tailwind::INPUT_ERROR if @contract.has_errors?),
            ("pl-11" if @contract.prefix.present?),
            @contract.class_name
          ].compact.join(" ")
        end

        def prefix_wrapper_classes
          Tailwind::INPUT_PREFIX_WRAPPER
        end

        def error_classes
          Tailwind::ERROR_TEXT
        end

        def input_attributes
          {
            class: input_classes,
            placeholder: @contract.placeholder,
            data: @contract.data
          }.compact
        end

        def render_attributes
          @base.attributes
        end
      end
    end
  end
end
