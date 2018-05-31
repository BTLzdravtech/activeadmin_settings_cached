# frozen_string_literal: true

module ActiveadminSettingsCached
  module DSL
    # Declares settings function.
    #
    # @api public
    #
    # @param [Hash] options
    # @option options [String] :model_name, settings model name override (default: uses name from global config.)
    # @option options [String] :starting_with, each key must starting with, (default: nil)
    # @option options [String] :key, root key can be replacement for starting_with, (default: nil)
    # @option options [String] :template custom, template rendering (default: 'admin/settings/index')
    # @option options [String] :template_object, object to use in templates (default: ActiveadminSettingsCached::Model instance)
    # @option options [String] :display, display settings override (default: nil)
    # @option options [String] :title, title value override (default: I18n.t('settings.menu.label'))
    # @option options [Proc] :after_save, callback for action after page update, (default: nil)
    def active_admin_settings_page(options = {}, &block)
      options.assert_valid_keys(*ActiveadminSettingsCached::Options::VALID_OPTIONS)

      options = ActiveadminSettingsCached::Options.options_for(options)
      coercion =
        ActiveadminSettingsCached::Coercions.new(options[:template_object].defaults, options[:template_object].display)

      content title: options[:title] do
        render partial: options[:template], locals: { settings_model: options[:template_object] }
      end

      page_action :update, method: :post do
        settings_params = params.require(:settings).permit!

        validation_errors = []
        coercion.cast_params(settings_params) do |name, value|
          begin
            options[:template_object].save(name, value)
          rescue ActiveRecord::RecordInvalid => invalid
            (validation_errors << invalid.record.errors[:setting]).flatten
          end
        end

        options[:after_save].call if options[:after_save].respond_to?(:call)

        if validation_errors.present?
          flash_text = "Error(s) : #{validation_errors.join(', ')}"
          render json: { flash: flash_text, status: 'failure' }
        else
          flash_text = 'Settings were successfully updated.'
          render json: { flash: flash_text, status: 'success' }
        end
      end

      instance_eval(&block) if block_given?
    end
  end
end
