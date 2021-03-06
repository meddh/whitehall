require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "should be invalid without a description" do
    contact = build(:contact, title: nil)
    refute contact.valid?
  end

  test "should be invalid if contact_form_url is invalid" do
    contact = build(:contact, contact_form_url: "not.a.url")
    refute contact.valid?
  end

  test "should be invalid without a contact_type" do
    contact = build(:contact, contact_type: nil)
    refute contact.valid?
  end

  test "should be valid with no postal address fields" do
    contact = build(:contact,
      recipient: "",
      street_address: "",
      locality: "",
      region: "",
      postal_code: "",
      country_id: ""
    )
    assert contact.valid?
  end

  test "should be invalid with only country but no street address" do
    country = create(:world_location)
    contact = build(:contact,
      recipient: "",
      street_address: "",
      locality: "",
      region: "",
      postal_code: "",
      country_id: country.id)
    refute contact.valid?
    assert_equal ["can't be blank"], contact.errors[:street_address]
  end

  test "should be invalid with only street address but no country" do
    contact = build(:contact,
      recipient: "",
      street_address: "123 Acacia Avenue",
      locality: "",
      region: "",
      postal_code: "",
      country_id: "")
    refute contact.valid?
    assert_equal ["can't be blank"], contact.errors[:country_id]
  end

  test "should be valid with only street address and country" do
    country = create(:world_location)
    contact = build(:contact,
      recipient: "",
      street_address: "123 Acacia avenue",
      locality: "",
      region: "",
      postal_code: "",
      country_id: country.id)
    assert contact.valid?
  end

  test "should return a country code" do
    contact = build(:contact, country: build(:world_location, iso2: 'GB'))
    assert_equal 'GB', contact.country_code
  end

  test "should return a country name" do
    contact = build(:contact, country: build(:world_location, name: 'United Kingdom'))
    assert_equal 'United Kingdom', contact.country_name
  end

  test "should allow creation of nested contact numbers" do
    contact = create(:contact, contact_numbers_attributes: [{label: "Telephone", number: "123"}])
    assert_equal 1, contact.contact_numbers.count
    assert_equal "Telephone", contact.contact_numbers[0].label
    assert_equal "123", contact.contact_numbers[0].number
  end

  test "should not create nested contact numbers if their attributes are blank" do
    contact = create(:contact, contact_numbers_attributes: [{label: "", number: ""}])
    assert_equal 0, contact.contact_numbers.count
  end

  test "should destroy associated contact numbers on destruction" do
    contact = create(:contact, contact_numbers: [create(:contact_number)])
    contact.destroy
    assert contact.contact_numbers.empty?
  end

  test 'removes itself from any home page lists when it is destroyed' do
    contact = create(:contact)
    list = create(:home_page_list)
    list.add_item(contact)

    contact.destroy

    refute list.shown_on_home_page?(contact)
  end

  test "#missing_translations should only include contactable translations" do
    organisation = create(:organisation, translated_into: [:de, :es, :fr])
    contact = create(:contact, contactable: organisation, translated_into: [:es])

    expected_locales = [:de, :fr].map { |l| Locale.new(l) }
    assert_equal expected_locales, contact.missing_translations
  end

  test "republishes dependent editions after update" do
    contact = create(:contact)
    news_article = create(:published_news_article, body: "For more information, get in touch at: [Contact:#{contact.id}]")
    corp_info_page = create(:published_corporate_information_page, body: "For free advice, please visit our office: [Contact:#{contact.id}]")
    EditionDependenciesPopulator.new(news_article).populate!
    EditionDependenciesPopulator.new(corp_info_page).populate!

    expect_republishing(news_article, corp_info_page)

    contact.update_attributes(title: "Changed contact title")
  end

  def expect_republishing(*editions)
    editions.each do |edition|
      Whitehall.publishing_api_client.expects(:put_content_item)
        .with(Whitehall.url_maker.public_document_path(edition),
          has_entries(content_id: edition.content_id, update_type: 'republish'))
    end
  end

end
