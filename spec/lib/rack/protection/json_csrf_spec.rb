describe Rack::Protection::JsonCsrf do
  it_behaves_like "any rack application"

  describe 'json response' do
    before do
      mock_app { |e| [200, {'Content-Type' => 'application/json'}, []]}
    end

    it "denies get requests with json responses with a remote referrer" do
      expect(get('/', {}, 'HTTP_REFERER' => 'http://evil.com')).not_to be_ok
    end

    it "accepts requests with json responses with a remote referrer when there's an origin header set" do
      expect(get('/', {}, 'HTTP_REFERER' => 'http://good.com', 'HTTP_ORIGIN' => 'http://good.com')).to be_ok
    end

    it "accepts requests with json responses with a remote referrer when there's an x-origin header set" do
      expect(get('/', {}, 'HTTP_REFERER' => 'http://good.com', 'HTTP_X_ORIGIN' => 'http://good.com')).to be_ok
    end

    it "accepts get requests with json responses with a local referrer" do
      expect(get('/', {}, 'HTTP_REFERER' => '/')).to be_ok
    end

    it "accepts get requests with json responses with no referrer" do
      expect(get('/', {})).to be_ok
    end

    it "accepts XHR requests" do
      expect(get('/', {}, 'HTTP_REFERER' => 'http://evil.com', 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest')).to be_ok
    end

  end

  describe 'not json response' do

    it "accepts get requests with 304 headers" do
      mock_app { |e| [304, {}, []]}
      expect(get('/', {}).status).to eq(304)
    end

  end

  describe 'with drop_session as default reaction' do
    it 'still denies' do
      mock_app do
        use Rack::Protection, :reaction => :drop_session
        run proc { |e| [200, {'Content-Type' => 'application/json'}, []]}
      end

      session = {:foo => :bar}
      get('/', {}, 'HTTP_REFERER' => 'http://evil.com', 'rack.session' => session)
      expect(last_response).not_to be_ok
    end
  end
end
