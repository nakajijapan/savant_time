class Archive < ActiveRecord::Base
  validates :aid, presence: true, uniqueness: true
  belongs_to :archive_job, foreign_key: :aid, primary_key: :jid, dependent: :destroy

  after_destroy :destroy_remote

  paginates_per 200

  # SQLiteでは8bit INTしか扱えず文字列として保持しているので、整数に変換してから返す
  def filesize
    super.to_i
  end

  def retrieve
    glacier = Glacier.new
    glacier.retrieve_archive(aid)
  end

  def verify
    return unless File.exists?(archive_job.fullpath)
    sha256 == Treehash.calculate_tree_hash(File.open(archive_job.fullpath))
  end

  private
  def destroy_remote
    glacier = Glacier.new
    glacier.destroy_archive(aid)
  end
end
