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
    end
  end
end
