class PastStanding < ApplicationRecord
  belongs_to :standing
  belongs_to :channel
end
