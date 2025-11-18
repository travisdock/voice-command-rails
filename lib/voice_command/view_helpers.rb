module VoiceCommand
  module ViewHelpers
    def voice_command_recorder_form(endpoint:, method: :post, form_options: {}, button_text: "Tap to record", status_text: "Tap to record again.", input_name: :audio, button_html: {}, status_html: {}, &block)
      options = form_options.deep_dup
      html_options = options.delete(:html) { {} }
      html_options[:data] = { controller: "audio-recorder" }.merge(html_options[:data] || {})
      html_options[:class] = build_class_names("voice-command-recorder", html_options[:class])
      html_options[:multipart] = true

      hidden_input_options = {
        data: { audio_recorder_target: "input" },
        accept: accepted_mime_types,
        style: "display:none",
        class: "voice-command-recorder__input"
      }

      default_button_options = {
        type: "button",
        class: "voice-command-recorder__button inline-flex items-center justify-center rounded-full bg-slate-900 px-4 py-2 text-white transition hover:bg-slate-800",
        data: {
          action: "audio-recorder#toggle",
          audio_recorder_target: "button"
        },
        "aria-pressed": "false"
      }

      default_status_options = {
        class: "voice-command-recorder__status mt-2 text-sm text-slate-500",
        id: "voice_command_status"
      }

      merged_button_options = merge_html_attributes(default_button_options, button_html)
      merged_status_options = merge_html_attributes(default_status_options, status_html)

      form_with(**options, url: endpoint, method: method, html: html_options) do |form|
        concat(form.file_field(input_name, hidden_input_options))
        concat(capture(form, &block)) if block_given?
        concat(button_tag(button_text, **merged_button_options))
        concat(content_tag(:div, status_text, **merged_status_options))
      end
    end

    private

    def accepted_mime_types
      Array(VoiceCommand.config.allowed_content_types)
        .select { |type| type.is_a?(String) && type.include?("/") }
        .join(", ")
    end

    def merge_html_attributes(defaults, overrides)
      return defaults unless overrides

      defaults.merge(overrides) do |key, old_value, new_value|
        case key.to_sym
        when :class
          build_class_names(old_value, new_value)
        when :data
          (old_value || {}).merge(new_value || {})
        else
          new_value
        end
      end
    end

    def build_class_names(*values)
      values.flatten.compact.reject(&:blank?).join(" ")
    end
  end
end
