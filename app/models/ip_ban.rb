class IpBan < ApplicationRecord
  belongs_to_creator
  validates_presence_of :reason, :ip_addr
  validates_uniqueness_of :ip_addr
  after_create do |rec|
    ModAction.log(:ip_ban_create, {ip_addr: rec.ip_addr})
  end
  after_destroy do |rec|
    ModAction.log(:ip_ban_delete, {ip_addr: rec.ip_addr})
  end

  def self.is_banned?(ip_addr)
    where("ip_addr >>= ?", ip_addr).exists?
  end

  def self.search(params)
    q = super

    if params[:ip_addr].present?
      q = q.where("ip_addr = ?", params[:ip_addr])
    end

    q.apply_default_order(params)
  end

  def validate_ip_addr
    if ip_addr.blank?
      errors[:ip_addr] << "is invalid"
    elsif ip_addr.ipv4? && ip_addr.prefix < 24
      errors[:ip_addr] << "may not have a subnet bigger than /24"
    elsif ip_addr.ipv6? && ip_addr.prefix < 64
      errors[:ip_addr] << "may not have a subnet bigger than /64"
    elsif ip_addr.private? || ip_addr.loopback? || ip_addr.link_local?
      errors[:ip_addr] << "must be a public address"
    end
  end

  def has_subnet?
    (ip_addr.ipv4? && ip_addr.prefix < 32) || (ip_addr.ipv6? && ip_addr.prefix < 128)
  end

  def subnetted_ip
    str = ip_addr.to_s
    str += "/" + ip_addr.prefix.to_s if has_subnet?
    str
  end
end
