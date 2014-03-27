require 'chef/resource'
require 'openssl'

class Chef
  class Resource
    class SslCertificate < Chef::Resource

      def initialize(name, run_context=nil)
        super
        @resource_name = :ssl_certificate
        @action = :create
        @allowed_actions.push(@action)
        @provider = Chef::Provider::SslCertificate

        # default values
        namespace(name)
        %w{
          key_path
          server_name
          key_name
          key_dir
          key_source
          key_bag
          key_item
          key_item_key
          key_encrypted
          key_secret_file
          key_content
          cert_path
          cert_name
          cert_dir
          cert_source
          cert_bag
          cert_item
          cert_item_key
          cert_encrypted
          cert_secret_file
          cert_content
        }.each do |var|
          self.instance_variable_set("@#{var}".to_sym, self.send("default_#{var}"))
        end
      end

      def depends_chef_vault?
        key_source == 'chef-vault' || cert_source == 'chef-vault'
      end

      # used by load_current_resource
      def load
        key = read_from_path(key_path)
        key_content(key) unless key.nil?
        cert = read_from_path(cert_path)
        cert_content(cert) unless cert.nil?
      end

      def exists?
        @key_content.kind_of?(String) and @cert_content.kind_of?(String)
      end

      def ==(o)
        key_path == o.key_path and
        cert_path == o.cert_path and
        server_name == o.server_name
      end

      alias :===  :==

      def namespace(arg=nil)
        unless arg.nil? or arg.kind_of?(Chef::Node) or arg.kind_of?(Chef::Node::ImmutableMash)
          arg = [ arg ].flatten
          arg = arg.inject(node) do |n, k|
            n.respond_to?(:has_key?) && n.has_key?(k) ? n[k] : nil
          end
        end
        set_or_return(
          :namespace,
          arg,
          :kind_of => [ Chef::Node, Chef::Node::ImmutableMash, Mash ]
        )
      end

      def server_name(arg=nil)
        set_or_return(
          :server_name,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      alias :canonical_name :server_name
      alias :domain :server_name

      # some common (key + cert) public methods

      def dir(arg)
        key_dir(arg)
        cert_dir(arg)
      end

      def source(arg)
        key_source(arg)
        cert_source(arg)
      end

      def bag(arg)
        key_bag(arg)
        cert_bag(arg)
      end

      def item(arg)
        key_item(arg)
        cert_item(arg)
      end

      def encrypted(arg)
        key_encrypted(arg)
        cert_encrypted(arg)
      end

      def secret_file(arg)
        key_secret_file(arg)
        cert_secret_file(arg)
      end

      # key public methods

      def key_name(arg=nil)
        set_or_return(
          :key_name,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      def key_dir(arg=nil)
        set_or_return(
          :key_dir,
          arg,
          :kind_of => String
        )
      end

      def key_path(arg=nil)
        set_or_return(
          :key_path,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      def key_source(arg=nil)
        set_or_return(
          :key_source,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      def key_bag(arg=nil)
        set_or_return(
          :key_bag,
          arg,
          :kind_of => String
        )
      end

      def key_item(arg=nil)
        set_or_return(
          :key_item,
          arg,
          :kind_of => String
        )
      end

      def key_item_key(arg=nil)
        set_or_return(
          :key_item_key,
          arg,
          :kind_of => String
        )
      end

      def key_encrypted(arg=nil)
        set_or_return(
          :key_encrypted,
          arg,
          :kind_of => String
        )
      end

      def key_secret_file(arg=nil)
        set_or_return(
          :key_secret_file,
          arg,
          :kind_of => String
        )
      end

      def key_content(arg=nil)
        set_or_return(
          :key_content,
          arg,
          :kind_of => String
        )
      end

      # cert public methods

      def cert_name(arg=nil)
        set_or_return(
          :key_name,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      def cert_dir(arg=nil)
        set_or_return(
          :cert_dir,
          arg,
          :kind_of => String
        )
      end

      def cert_path(arg=nil)
        set_or_return(
          :cert_path,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      def cert_source(arg=nil)
        set_or_return(
          :cert_source,
          arg,
          :kind_of => String,
          :required => true
        )
      end

      def cert_bag(arg=nil)
        set_or_return(
          :cert_bag,
          arg,
          :kind_of => String
        )
      end

      def cert_item(arg=nil)
        set_or_return(
          :cert_item,
          arg,
          :kind_of => String
        )
      end

      def cert_item_key(arg=nil)
        set_or_return(
          :cert_item_key,
          arg,
          :kind_of => String
        )
      end

      def cert_encrypted(arg=nil)
        set_or_return(
          :cert_encrypted,
          arg,
          :kind_of => String
        )
      end

      def cert_secret_file(arg=nil)
        set_or_return(
          :cert_secret_file,
          arg,
          :kind_of => String
        )
      end

      def cert_content(arg=nil)
        set_or_return(
          :cert_content,
          arg,
          :kind_of => String
        )
      end

      private

      # key private methods

      def default_key_path
        lazy { @default_key_path ||= ::File.join(key_dir, key_name) }
      end

      def default_server_name
        lazy { read_namespace('server_name') || node['fqdn'] }
      end

      def default_key_name
        "#{name}.key"
      end

      def default_key_dir
        case node['platform']
        when 'debian', 'ubuntu'
          '/etc/ssl/private'
        when 'redhat', 'centos', 'fedora', 'scientific', 'amazon'
          '/etc/pki/tls/private'
        else
          '/etc'
        end
      end

      def default_key_source
        lazy do
          read_namespace(['ssl_key', 'source']) or
          read_namespace('source')
        end
      end

      def default_key_bag
        lazy do
          read_namespace(['ssl_key', 'bag']) or
          read_namespace('bag')
        end
      end

      def default_key_item
        lazy do
          read_namespace(['ssl_key', 'item']) or
          read_namespace('item')
        end
      end

      def default_key_item_key
        lazy { read_namespace(['ssl_key', 'item_key']) }
      end

      def default_key_encrypted
        lazy do
          read_namespace(['ssl_key', 'encrypted']) or
          read_namespace('encrypted')
        end
      end

      def default_key_secret_file
        lazy do
          read_namespace(['ssl_key', 'secret_file']) or
          read_namespace('secret_file') or
          Chef::Config[:encrypted_data_bag_secret]
        end
      end

      def default_key_content
        # TODO needs to be cached?
        lazy do
          @default_key_content ||= begin
            case key_source
            # TODO attribute source has sense?
            # when 'attribute'
            #   if @ssl_key.attribute?('content') and @ssl_key['content'].kind_of?(String)
            #     @ssl_key['content']
            #   else
            #     Chef::Application.fatal!('Cannot read SSL key from content key value')
            #   end
            when 'data-bag'
              read_from_data_bag(key_bag, key_item, key_item_key, key_encrypted, key_secret_file) or
                Chef::Application.fatal!("Cannot read SSL key from data bag: #{key_bag}.#{key_item}->#{key_item_key}")
            when 'chef-vault'
              read_from_chef_vault(key_bag, key_item, key_item_key) or
                Chef::Application.fatal!("Cannot read SSL key from chef-vault: #{key_bag}.#{key_item}->#{key_item_key}")
            when 'file'
              read_from_path(key_path) or
                Chef::Application.fatal!("Cannot read SSL key from path: #{key_path}")
            when 'self-signed'
              read_from_path(key_path) or generate_key
            else
              Chef::Application.fatal!("Cannot read SSL key, unknown source: #{ssl_key_source}")
            end
          end # @default_key_content ||=
        end # lazy
      end

      # cert private methods

      def default_cert_path
        lazy { @default_cert_path ||= ::File.join(cert_dir, cert_name) }
      end

      def default_cert_name
        "#{name}.pem"
      end

      def default_cert_dir
        case node['platform']
        when 'debian', 'ubuntu'
          '/etc/ssl/certs'
        when 'redhat', 'centos', 'fedora', 'scientific', 'amazon'
          '/etc/pki/tls/certs'
        else
          '/etc'
        end
      end

      def default_cert_source
        lazy do
          read_namespace(['ssl_cert', 'source']) or
          read_namespace('source')
        end
      end

      def default_cert_bag
        lazy do
          read_namespace(['ssl_cert', 'bag']) or
          read_namespace('bag')
        end
      end

      def default_cert_item
        lazy do
          read_namespace(['ssl_cert', 'item']) or
          read_namespace('item')
        end
      end

      def default_cert_item_key
        lazy { read_namespace(['ssl_cert', 'item_key']) }
      end

      def default_cert_encrypted
        lazy do
          read_namespace(['ssl_cert', 'encrypted']) or
          read_namespace('encrypted')
        end
      end

      def default_cert_secret_file
        lazy do
          read_namespace(['ssl_cert', 'secret_file']) or
          read_namespace('secret_file') or
          Chef::Config[:encrypted_data_bag_secret]
        end
      end

      def default_cert_content
        lazy do
          @default_cert_content ||= begin
            case cert_source
            # TODO attribute source has sense?
            # when 'attribute'
            #   if @ssl_cert.attribute?('content') and @ssl_cert['content'].kind_of?(String)
            #     @ssl_cert['content']
            #   else
            #     Chef::Application.fatal!('Cannot read SSL certificate from content key value')
            #   end
            when 'data-bag'
              read_from_data_bag(cert_bag, cert_item, cert_item_key, cert_encrypted, cert_secret_file) or
                Chef::Application.fatal!("Cannot read SSL certificate from data bag: #{cert_bag}.#{cert_item}->#{cert_item_key}")
            when 'chef-vault'
              read_from_chef_vault(cert_bag, cert_item, cert_item_key) or
                Chef::Application.fatal!("Cannot read SSL certificate from chef-vault: #{cert_bag}.#{cert_item}->#{cert_item_key}")
            when 'file'
              read_from_path(cert_path) or
                Chef::Application.fatal!("Cannot read SSL certificate from path: #{cert_path}")
            when 'self-signed'
              content = read_from_path(cert_path)
              unless content and verify_self_signed_cert(key_content, content, server_name)
              content = generate_self_signed_cert(key_content, server_name)
              end
              content
            else
              Chef::Application.fatal!("Cannot read SSL cert, unknown source: #{ssl_key_source}")
            end
          end # @default_cert_content ||=
        end # lazy
      end

      # reading private methods

      # read some values from node namespace avoiding exceptions
      def read_namespace(ary)
        ary = [ ary ].flatten
        if ary.kind_of?(Array)
          ary.inject(namespace) do |n, k|
            n.respond_to?(:has_key?) && n.has_key?(k) ? n[k] : nil
          end
        end
      end
          
      def read_from_path(path)
        if ::File.exists?(path)
          ::IO.read(path)
        end
      end

      def read_from_data_bag(bag, item, item_key, encrypted = false, secret_file = nil)
        begin
          if encrypted
            item = Chef::EncryptedDataBagItem.load(bag, item, secret_file)
          else
            item = Chef::DataBagItem.load(bag, item)
          end
          item[item_key]
        rescue
          nil
        end
      end

      def read_from_chef_vault(bag, item, item_key)
        require 'chef-vault'

        begin
          item = ChefVault::Item.load(bag, item)
          item[item_key]
        rescue
          nil
        end
      end

      # ssl generation private methods

      def generate_key
        OpenSSL::PKey::RSA.new(2048).to_pem
      end

      def generate_self_signed_cert(key, hostname)
        # based on https://gist.github.com/nickyp/886884
        key = OpenSSL::PKey::RSA.new(key)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = OpenSSL::BN.rand(160)
        cert.subject = OpenSSL::X509::Name.parse("/CN=#{hostname}")
        cert.issuer = cert.subject # self-signed
        cert.public_key = key.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + 10 * 365 * 24 * 60 * 60 # 10 years validity
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
        cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
        cert.add_extension(ef.create_extension('authorityKeyIdentifier', 'keyid:always,issuer:always', false))
        cert.sign(key, OpenSSL::Digest::SHA256.new)
        cert.to_pem
      end

      def verify_self_signed_cert(key, cert, hostname)
        key = OpenSSL::PKey::RSA.new(key)
        cert = OpenSSL::X509::Certificate.new(cert)
        subject = OpenSSL::X509::Name.parse("/CN=#{hostname}")
        key.params['n'] == cert.public_key.params['n'] && cert.subject == subject && cert.issuer == subject
      end

    end
  end
end
