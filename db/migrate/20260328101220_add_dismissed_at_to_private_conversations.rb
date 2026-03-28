class AddDismissedAtToPrivateConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :private_conversations, :sender_dismissed_at, :datetime
    add_column :private_conversations, :recipient_dismissed_at, :datetime
  end
end
