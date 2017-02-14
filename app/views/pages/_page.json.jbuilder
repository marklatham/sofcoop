json.extract! page, :id, :user_id, :visible, :title, :slug, :body, :created_at, :updated_at
json.url page_url(page, format: :json)