class RatingVote < ApplicationRecord
  belongs_to :article
  belongs_to :user

  validates :user_id, uniqueness: { scope: %i[article_id context] }
  validates :group, inclusion: { in: %w[experience_level] }
  validates :context, inclusion: { in: %w[explicit readinglist_reaction] }
  validates :rating, numericality: { greater_than: 0.0, less_than_or_equal_to: 10.0 }
  validate :permissions

  after_create_commit :assign_article_rating

  counter_culture :article
  counter_culture :user

  def assign_article_rating
    ratings = article.rating_votes.where(group: group).pluck(:rating)
    average = ratings.sum / ratings.size

    article.update_columns(
      experience_level_rating: average,
      experience_level_rating_distribution: ratings.max - ratings.min,
      last_experience_level_rating_at: Time.current,
    )
  end

  private

  def permissions
    errors.add(:user_id, "is not permitted to take this action.") if context == "explicit" && !user&.trusted && user_id != article&.user_id
  end
end
