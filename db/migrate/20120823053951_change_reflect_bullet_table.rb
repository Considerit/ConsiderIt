class ChangeReflectBulletTable < ActiveRecord::Migration
  def up
    add_column :reflect_bullets, :comment_type, :text
    add_column :reflect_bullet_revisions, :comment_type, :text
    Reflect::ReflectBulletRevision.all.each do |b|
      b.comment_type = 'Comment'
      b.save
    end
    Reflect::ReflectBullet.all.each do |b|
      b.comment_type = 'Comment'
      b.save
    end

  end

  def down
    remove_column :reflect_bullets, :comment_type
    remove_column :reflect_bullet_revisions, :comment_type
  end
end
