module RepertoireCore
  module User
    def self.included(base)
      base.class_eval do
        include RepertoireCore::Mixins::UserProperties
        include RepertoireCore::Mixins::UserAuthorization
      end
    end
  end
end