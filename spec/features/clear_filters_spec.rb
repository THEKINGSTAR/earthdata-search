# EDSC-37 As a user, I want to clear my collection filters so that I may start a new search

require 'spec_helper'

describe "'Clear Filters' button", reset: false do
  before :all do
    load_page :search, facets: true, env: :sit
  end

  it "clears keywords" do
    fill_in "keywords", with: "AST_L1A"
    expect(page).to have_content('ASTER L1A')

    click_link "Clear Filters"
    expect(page).to have_no_content('ASTER L1A')
    expect(page.find("#keywords")).to have_no_text("AST_L1A")
  end

  it 'clears spatial' do
    create_point(0, 0)
    wait_for_xhr
    collections_within_point = find('.master-overlay-tab-title strong').text
    click_link 'Clear Filters'
    wait_for_xhr
    collections_without_point = find('.master-overlay-tab-title strong').text
    expect(collections_without_point).to be > collections_within_point
  end

  context "clears temporal", data_specific: true do
    after :each do
      # close temporal dropdown
      click_link "Temporal"
      click_link "Clear Filters"
      wait_for_xhr
    end

    it "range" do
      script = "var temporal = edsc.models.page.current.query.temporal.applied;
                temporal.start.date(new Date('1978-12-01T00:00:00Z'));
                temporal.stop.date(new Date('1979-12-01T00:00:00Z'));
                temporal.isRecurring(false);
                null;"
      page.execute_script(script)
      fill_in "keywords", with: 'C1000001409-EDF_OPS'

      expect(page).to have_no_content("A minimal dif dataset")

      click_link "Clear Filters"

      fill_in "keywords", with: 'C1000000083-DEMO_PROV'
      expect(page).to have_content("A minimal dif dataset")
      click_link "Temporal"
      expect(page.find("#collection-temporal-range-start")).to have_no_text("1978-12-01 00:00:00")
      expect(page.find("#collection-temporal-range-stop")).to have_no_text("1979-12-01 00:00:00")
      page.find('body > footer .version').click # Click away from timeline
    end

    it "recurring" do
      script = "var temporal = edsc.models.page.current.query.temporal.applied;
                temporal.start.date(new Date('1970-12-01T00:00:00Z'));
                temporal.stop.date(new Date('1975-12-01T00:00:00Z'));
                temporal.isRecurring(true);
                null;"
      page.execute_script(script)

      fill_in "keywords", with: 'C1000001409-EDF_OPS'
      expect(page).to have_no_content("MEaSUREs Arctic Sea Ice Characterization Daily 25km EASE-Grid 2.0 V001")

      click_link "Clear Filters"
      wait_for_xhr
      fill_in "keywords", with: 'C1000001409-EDF_OPS'
      expect(page).to have_content("MEaSUREs Arctic Sea Ice Characterization Daily 25km EASE-Grid 2.0 V001")
      click_link "Temporal"
      expect(page.find("#collection-temporal-recurring-start")).to have_no_text("1970-12-01 00:00:00")
      expect(page.find("#collection-temporal-recurring-stop")).to have_no_text("1975-12-31 00:00:00")
      expect(page.find(".temporal-recurring-year-range-value")).to have_text("1960 - #{Time.new.year}")
      page.find('body > footer .version').click # Click away from timeline
    end
  end

  it 'clears facets' do
    # 'Features' facet is already expanded, no need to click it
    find('.facets-item', text: 'Map Imagery').click

    within(:css, '.features') do
      expect(page).to have_content('Map Imagery')
      expect(page).to have_css('.facets-item.selected')
    end

    click_link 'Clear Filters'

    expect(page).to have_no_css('.facets-item.selected')
  end
end
