module Hancock
  class Envelope
    
    BOUNDARY = 'AAA'

    def self.find
      ###
    end

    def initialize
      @documents = []
      @recipients = {
        signers: []
      }

      @docusign_headers = {
        'X-DocuSign-Authentication' => {
          'Username' => Hancock.username,
          'Password' => Hancock.password,
          'IntegratorKey' => Hancock.integrator_key
        }.to_json
      }

      @files_array = []
    end

    def add_document(document) 
      @documents << { documentId: document.identifier, name: document.name }
      @files_array << document
    end

    def add_signature_request(recepient, document, tabs) 
      doc_signer = {
        email: recepient.email,
        name: recepient.name,
        recipientId:  recepient.identifier
      }

      doc_signer[:tabs] = {
        #here we can add more types
        initialHereTabs: get_tabs( tabs, "initial_here", document.identifier),
        signHereTabs:    get_tabs( tabs, "sign_here" , document.identifier),
      }

      @recipients[:signers] << doc_signer
    end

    #################need refactor    
    def form_post_body status     
      post_body = ''
      post_body << "\r\n"
      post_body << "--#{BOUNDARY}\r\n"
      post_body << "Content-Type: application/json\r\n"
      post_body << "Content-Disposition: form-data\r\n"
      post_body << "\r\n"
      post_body << get_post_params(status).to_json
      post_body << "\r\n"
      post_body << "--#{BOUNDARY}\r\n"
      

      @files_array.each do |f|
        post_body << "Content-Type: application/pdf\r\n"
        post_body << "Content-Disposition: file; filename=#{f.name}; documentid=#{f.identifier}\r\n"
        post_body << "\r\n"
        post_body << IO.read(f.file) 
        post_body << "\r\n"
      end

      post_body << "\r\n"
      post_body << "--#{BOUNDARY}--\r\n"
    end

    def send!
      uri = build_uri("/accounts/#{Hancock.account_id}/envelopes")
      content_headers = { 
        'Content-Type' => "multipart/form-data, boundary=#{BOUNDARY}" 
      }

      post_request(uri, form_post_body("sent"), get_headers(content_headers))
    end

    def save
      uri = build_uri("/accounts/#{Hancock.account_id}/envelopes")
      content_headers = { 
        'Content-Type' => "multipart/form-data, boundary=#{BOUNDARY}" 
      }

      post_request(uri, form_post_body("created"), get_headers(content_headers))
    end
    #################################

    def documents
      uri = build_uri("/accounts/#{Hancock.account_id}/envelopes/#{envelope_id}/documents")
      content_headers = { 'Content-Type' => 'application/json' }

      get_request(uri, get_headers(content_headers))
    end

    def recipients
      uri = build_uri("/accounts/#{Hancock.account_id}/envelopes/#{envelope_id}/recipients")
      content_headers = { 'Content-Type' => 'application/json' }

      get_request(uri, get_headers(content_headers))
    end

    def status
      #
    end

    #
    #for test request from console
    #
    # def self.test
    #   envelope = Hancock::Envelope.new
    #   doc1 = File.open("test.pdf")
    #   document1 = Hancock::Document.new(file: doc1, name: "test", extension: "pdf", identifier: "123")
    #   recipient1 = Hancock::Recipient.new(name: "Owner", email: "kolya.bokhonko@gmail.com", routing_order: 1)
    #   envelope.add_document(document1)
    #   tab1 = Hancock::Tab.new(type: "sign_here", label: "Vas", coordinates: [2, 100], page_number: 1)
    #   envelope.add_signature_request(recipient1, document1, [tab1])
    #   envelope.save
    # end

    private
      def post_request(uri, body_post, headers)
        http = initialize_http(uri)

        request = Net::HTTP::Post.new(uri.request_uri, headers)
        request.body = body_post
        http.request(request) # return response
      end

      def get_request(uri, headers)
        http = initialize_http(uri)

        request = Net::HTTP::Get.new(uri.request_uri, headers)
        http.request(request) # return response
      end

      def build_uri(url)
        URI.parse("#{Hancock.endpoint}/#{Hancock.api_version}#{url}")
      end

      def get_post_params(status)
        { 
          emailBlurb:   "emailBlurb",
          emailSubject: "emailSubject",
          status: "#{status}",
          documents: @documents,
          recipients: @recipients,
        }
      end

      def get_headers(user_defined_headers={})
        default = {
          'Accept' => 'json' 
        }

        default.merge!(user_defined_headers) if user_defined_headers
        @docusign_headers.merge(default)
      end

      def initialize_http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http
      end

      def get_tabs(tabs, type, document_id)
        tabs_by_type(tabs, type).each_with_object([]) do |tab, tab_array|
          tab_array << generate_tab(tab, document_id)
        end
      end

      def tabs_by_type(tabs, type)
        tabs.select{ |h| h.type == type }
      end

      def generate_tab(tab, document_id)
        tab_hash = {}

        if tab.is_a? Hancock::AnchoredTab
          tab_hash[:anchorString]  = tab.anchor_text || 'Signature 1'
          tab_hash[:anchorXOffset] = tab.offset[0] || '0'
          tab_hash[:anchorYOffset] = tab.offset[1] || '0'
          tab_hash[:IgnoreIfNotPresent] = 1
        else
          tab_hash[:tabLabel]   = tab.label || 'Signature 1'
          tab_hash[:xPosition]  = tab.coordinates[0] || '0'
          tab_hash[:yPosition]  = tab.coordinates[1] || '0'          
        end

        tab_hash[:documentId] = document_id || '0'
        tab_hash[:pageNumber] = tab.page_number
        tab_hash
      end
  end
end