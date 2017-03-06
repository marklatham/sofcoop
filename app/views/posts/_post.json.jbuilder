json.extract! post, :id, :user_id, :visible, :title, :slug, :body, :created_at, :updated_at
json.url post_url(post, format: :json)