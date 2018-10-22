require 'spec_helper'

describe 'Granule list', reset: false do
  extend Helpers::CollectionHelpers

  before :all do
    Capybara.reset_sessions!
    load_page :search
    # login
  end

  context 'for all collections with granules' do
    before :all do
      visit('/search/granules?p=C92711294-NSIDC_ECS&tl=1501695072!4!!&q=C92711294-NSIDC_ECS&ok=C92711294-NSIDC_ECS')
      wait_for_xhr
    end
    it 'provides a text field to search for single or multiple granules by granule IDs' do
      expect(page).to have_selector('#granule-ids')
    end

    it 'provides a button to get collection details' do
      expect(granule_list).to have_link('View collection details')
    end

    it 'provides a button to get download the collection' do
      expect(granule_list).to have_button('Download')
    end

    it 'provides a button to edit granule filters' do
      expect(granule_list).to have_link('Filter granules')
    end

    it 'provides a button to download single granule' do
      within '#granules-scroll .panel-list-item:nth-child(1)' do
        expect(page).to have_link('Download single granule data')
        expect(page).to have_css('a[href="https://n5eil01u.ecs.nsidc.org/DP5/MOST/MOD10A1.005/2017.01.01/MOD10A1.A2017001.h34v09.005.2017003060855.hdf"]')
      end
    end

    it 'displays start and end temporal labels' do
      within '#granules-scroll .panel-list-item:nth-child(1)' do
        expect(page).to have_content('START 2017-01-01 23:45:00')
        expect(page).to have_content('END 2017-01-01 23:50:00')
      end
    end

    context 'entering multiple granule IDs' do
      before :all do
        fill_in 'granule-ids', with: "MOD10A1.A2016001.h31v13.005.2016006204744.hdf,MOD10A1.A2016001.h31v12*\t"
        wait_for_xhr
      end

      after :all do
        click_link "Filter granules"
        wait_for_xhr
        click_button "granule-filters-clear"
        wait_for_xhr
        find('#granule-search').click_link('close')
      end

      it 'filters granules down to 2 results' do
        expect(page).to have_content('Showing 2 of 2 matching granules')
      end

      it 'finds the granules' do
        expect(page).to have_content('MOD10A1.A2016001.h31v13.005.2016006204744.hdf')
        expect(page).to have_content('MOD10A1.A2016001.h31v12.005.2016006204741.hdf')
      end
    end

    context "clicking on the collection details button" do
      before :all do
        Capybara::Screenshot.screenshot_and_open_image
        granule_list.click_link('View collection details')
        # page.find('.collection-title-link').click
        wait_for_xhr
        Capybara::Screenshot.screenshot_and_open_image
      end

      after :all do
        collection_details.click_link('Back to Granules')
        wait_for_xhr
      end

      it "displays the collection details" do
        expect(page).to have_visible_collection_details
        expect(page).to have_content('nsidc@nsidc.org')
      end

      it "displays back navigation with the appropriate text" do
        expect(collection_details).to have_link('Back to Granules')
      end
    end

    context "clicking on the edit filters button" do
      before :all do
        # dismiss_banner
        Capybara::Screenshot.screenshot_and_open_image
        granule_list.click_link('Filter granules')
        wait_for_xhr
      end

      after :all do
        find('#granule-search').click_link('close')
      end

      it "allows the user to edit granule filters" do
        expect(page).to have_content('Day / Night Flag')
      end

      context "and editing a filter" do
        before :all do
          select 'Day only', from: "day-night-select"
        end

        after :all do
          select 'Anytime', from: "day-night-select"
        end

        it "shows the filters in an applied state" do
          Capybara::Screenshot.screenshot_and_open_image
          expect(granule_list).to have_selector('.button-highlighted[title="Hide granule filters"]')
        end
      end
    end

    context "clicking the exclude granule button" do
      before :all do
        # dismiss_banner
        # Capybara::Screenshot.screenshot_and_open_image
        first_granule_list_item.click
        first_granule_list_item.click_link "Remove granule"
        wait_for_xhr
      end

      after :all do
        click_link "Filter granules"
        wait_for_xhr
        click_button "granule-filters-clear"
        find('#granule-search').click_link('close')
      end

      it "removes the selected granule from the list" do
        expect(page).to have_no_content('FIFE_STRM_15M.80611715.s15')
        expect(page).to have_css('#granule-list .panel-list-item', count: 19)
      end

      it "shows undo button to re-add the granule" do
        expect(page).to have_content("Granule excluded. Undo")
      end

      context "until all granules on current page are excluded" do
        before :all do
          num_of_clicks = 19
          while num_of_clicks > 0
            first_granule_list_item.click_link "Remove granule"
            num_of_clicks -= 1
            wait_for_xhr
          end
        end

        after :all do
          Capybara.reset_sessions!
          load_page :search
          fill_in 'keywords', with: 'C92711294-NSIDC_ECS'
          view_granule_results('MODIS/Terra Snow Cover Daily L3 Global 500m SIN Grid V005')

          first_granule_list_item.click
          first_granule_list_item.click_link "Remove granule"
          wait_for_xhr
        end

        it "loads next page" do
          expect(page.text).to match(/Showing [1-9]\d* of 1855868 matching granules/)
          expect(page).to have_content("Granule excluded. Undo")
        end
      end

      context "and clicking the undo button" do
        before :all do
          click_link "Undo"
        end

        after :all do
          first_granule_list_item.click_link "Remove granule"
        end

        it "shows the excluded granule in the granule list" do
          expect(page).to have_content('MOD10A1.A2017001.h34v09.005.2017003060855.hdf')
          expect(page).to have_css('#granule-list .panel-list-item', count: 20)
        end

        it "selects the previously excluded granule" do
          expect(page).to have_css('.panel-list-list li:nth-child(1).panel-list-selected')
        end
      end

      context "and changing granule query" do
        before :all do
          click_link "Filter granules"
          wait_for_xhr
          check "Find only granules that have browse images."
          wait_for_xhr
        end

        after :all do
          uncheck "Find only granules that have browse images."
          click_link "Add it back"
          wait_for_xhr
          find('#granule-search').click_link('close')
          first_granule_list_item.click
          first_granule_list_item.click_link "Remove granule"
          wait_for_xhr
        end

        it "removes the undo button" do
          expect(page).to have_no_content("Granule excluded. Undo")
        end
      end
    end
  end

  context "for collections with many granule results" do
    before :all do
      visit('/search/granules?p=C179002914-ORNL_DAAC&tl=1501695072!4!!&q=C179002914-ORNL_DAAC&ok=C179002914-ORNL_DAAC')
      wait_for_xhr
    end
    context "clicking on a collection result" do

      it "displays the first granule results in a list that pages by 20" do
        expect(page).to have_css('#granule-list .panel-list-item', count: 20)
        page.execute_script "$('#granule-list .master-overlay-content')[0].scrollTop = 10000"
        expect(page).to have_css('#granule-list .panel-list-item', count: 40)
        expect(page).to have_no_content('Loading granules...')
      end
    end
  end

  context "for collections with few granule results" do
    before :all do
      visit('/search/granules?p=C179003380-ORNL_DAAC&tl=1501695072!4!!&q=C179003380-ORNL_DAAC&ok=C179003380-ORNL_DAAC')
      wait_for_xhr
    end

    context "clicking on a collection result" do

      it "displays all available granule results" do
        expect(page).to have_css('#granule-list .panel-list-item', count: 2)
      end

      it "does not attempt to load additional granule results" do
        expect(page).to have_no_text("Loading granules...")
      end
    end
  end

  context "for collections without granules" do
    before do
      set_temporal('2018-01-01 00:00:00', '2018-01-31 23:59:59')
    end

    use_collection 'C1426717545-LANCEMODIS', 'MODIS/Aqua Aerosol 5-Min L2 Swath 3km - NRT'

    context "clicking on a collection result" do
      before :all do
        visit('/search?q=C179002107-SEDAC&ok=C179002107-SEDAC')
        wait_for_xhr
        # dismiss_banner
        # expect(page).to have_visible_collection_results
        first_collection_result.click
        wait_for_xhr
      end

      it "shows no granules" do
        expect(page).to have_no_css('#granule-list .panel-list-item')
      end

      it "does not attempt to load additional granule results" do
        expect(page).to have_no_text("Loading granules...")
      end
    end
  end

  context 'for collections whose granules have more than one downloadable links' do

    context 'clicking on the single granule download button when the links have titles' do
      before :all do
        visit('/search/granules?p=C1000000042-LANCEAMSR2&tl=1501695072!4!!&q=C1000000042-LANCEAMSR2&ok=C1000000042-LANCEAMSR2')
        wait_for_xhr
        within '#granules-scroll .panel-list-item:nth-child(1)' do
          find('a[data-toggle="dropdown"]').click
        end
      end

      after :all do
        within '#granules-scroll .panel-list-item:nth-child(1)' do
          find('a[data-toggle="dropdown"]').click
        end
      end

      it 'shows a dropdown with all the downloadable granules' do
        within '#granules-scroll .panel-list-item:nth-child(1)' do
          expect(page).to have_content('Online access to AMSR-2 Near-Real-Time LANCE Products (primary)')
          expect(page).to have_content('Online access to AMSR-2 Near-Real-Time LANCE Products (backup)')
        end
      end
    end

    context 'clicking on the single granule download button when the links do not have titles', data_specific: true do
      before :all do
        visit('/search/granules?p=C1353062857-NSIDC_ECS&tl=1502209871!4!!&q=NSIDC-0481&ok=NSIDC-0481')
        wait_for_xhr
        within '#granules-scroll .panel-list-item:nth-child(1)' do
          find('a[data-toggle="dropdown"]').click
        end
      end

      after :all do
        within '#granules-scroll .panel-list-item:nth-child(1)' do
          find('a[data-toggle="dropdown"]').click
        end
      end

      it 'shows a dropdown with all the downloadable granules' do
        within '#granules-scroll .panel-list-item:nth-child(1)' do
          expect(page).to have_content('TSX_W69.10N_31Dec16_11Jan17_10-05-59_ex_v1.2.tif')
          expect(page).to have_content('TSX_W69.10N_31Dec16_11Jan17_10-05-59_ey_v1.2.tif')
          expect(page).to have_content('TSX_W69.10N_31Dec16_11Jan17_10-05-59_v1.2.meta')
          expect(page).to have_content('TSX_W69.10N_31Dec16_11Jan17_10-05-59_vx_v1.2.tif')
          expect(page).to have_content('TSX_W69.10N_31Dec16_11Jan17_10-05-59_vy_v1.2.tif')
        end
      end
    end
  end

  context 'for collections whose granules have duplicate downloadable links, with one pointing to https and the other ftp' do
    before :all do
      # A collection known to have duplicate downloadable links
      visit('/search/granules?p=C1444742099-PODAAC&tl=1501695072!4!!&q=C1444742099-PODAAC&ok=C1444742099-PODAAC')
      wait_for_xhr
      within '#granules-scroll .panel-list-item:nth-child(1)' do
        # If the test works, this dropdown won't even exist...
        if page.has_css?('a[data-toggle="dropdown"]')
          find('a[data-toggle="dropdown"]').click
        end
      end
    end

    it 'only shows the http link' do
      expect(page).not_to have_link("The FTP location for the granule.")
    end
  end

  context "for collections that are known to cause download delays" do
    before :all do
      visit('/search/granules?cmr_env=sit&p=C24931-LAADS&tl=1501695072!4!!&q=C24931-LAADS&ok=C24931-LAADS')
      wait_for_xhr
      click_button('Download')
    end
    it "shows a modal warning of the delay" do
      expect(page).to have_css('#delayWarningModalLabel')
      expect(page).to have_text('Message from data provider: This is an optional message.')
    end
  end

  context 'for collections that have granules without end times', data_specific: true do
    before :all do
      visit('/search/granules?cmr_env=uat&p=C1000-LPDAAC_TS2')
    end

    it 'displays correct start and end temporal labels' do
      within '#granules-scroll .panel-list-item:nth-child(1)' do
        expect(page).to have_content('START 2018-08-04 23:28:02')
        expect(page).to have_content('END Not Provided')
      end
    end
  end
end
