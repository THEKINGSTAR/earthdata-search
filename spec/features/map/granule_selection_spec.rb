require "spec_helper"

describe "Granule selection", reset: false do
  extend Helpers::CollectionHelpers
  Capybara.ignore_hidden_elements = true

  is_temporal_ordered_script = """
    result = (function() {
      var layers = $('#map').data('map').map._layers, key, layer, result;
      for (key in layers) {
        if (layers[key]._getBackTile) {
          layer = layers[key];
          break;
        }
      }
      if (!layer) {
        result = true;
      }
      else {
        result = layer._results[0].getTemporal() > layer._results[1].getTemporal() && layer._results[0].id != layer.stickyId;
      }
      return result;
    })();
    return result;
    """

  is_granule_panel_visible_script = """
    result = (function() {
      var list = $('#granule-list .master-overlay-content.panel-list');
      var top = list.offset().top;
      var bottom = top + list.height() - 150;
      var selected = $('.panel-list-selected').offset().top;

      if (selected + 5 > top && selected - 5 < bottom) {
        return true;
      } else {
        return false;
      }
    })();
    return result;
  """

  context "clicking on a granule in the result list" do
    before :all do
      load_page :search, bounding_box: [0, 0, 15, 15], focus: 'C203234448-LAADS'

      # Click on a bottom one to test re-ordering
      nth_granule_list_item(10).click
      wait_for_xhr
    end

    after :all do
      nth_granule_list_item(10).click
    end

    it "highlights the selected granule in the granule list" do
      expect(granule_list).to have_selector('.panel-list-selected', count: 1)
    end

   # EDSC-1395: Disabling this test for the moment as it is being flaky.
   # This test is questionable as I do not see how the presence of
   # 5 locators of '#map path' is evidence that the selected granule is highlighted.
   # Further, this value seems to change from 5 to 3 then back to 5 almost
   # randomly, making this test very flaky.  Re-evaluate at appropriate time.

   # it "highlights the selected granule on the map" do
   #   expect(page).to have_selector('#map path', count: 5)
   # end

    it "displays a link to remove the granule in the granule list" do
      expect(granule_list).to have_link('Remove granule')
    end

    it "displays a link to remove the granule on the map" do
      expect(page).to have_selector('#map .panel-list-remove', count: 1)
    end

    it "displays the granule's temporal extents on the map" do
      expect(page).to have_selector('.granule-spatial-label-temporal', count: 1)
    end

    it "displays the granule above all other granules" do
      synchronize do
        expect(page.execute_script(is_temporal_ordered_script)).to be_false
      end
    end

    it "centers the map over the selected granule" do
      expect(page).to match_map_center(-9, 7)
    end

    it "zooms the map to the selected granule" do
      script = "$('#map').data('map').map.getZoom()"
      result = page.evaluate_script script
      expect(result).to eq(2)
    end

    context "pressing the up button" do
      before :all do
        keypress('#granule-list', :up)
      end
      after :all do
        keypress('#granule-list', :down)
      end

      it "highlights the previous granule" do
        expect(page).to have_css('.panel-list-list li:nth-child(9).panel-list-selected')
      end

      it "scrolls to the selected granule" do
        expect(page.execute_script(is_granule_panel_visible_script)).to be_true
      end

      it "centers the map over the selected granule" do
        expect(page).to match_map_center(-9, 7)
      end

      it "zooms the map to the selected granule" do
        script = "$('#map').data('map').map.getZoom()"
        result = page.evaluate_script script
        expect(result).to eq(2)
      end
    end

    context "pressing the down button" do
      before :all do
        keypress('#granule-list', :down)
      end
      after :all do
        keypress('#granule-list', :up)
      end

      it "highlights the next granule" do
        expect(page).to have_css('.panel-list-list li:nth-child(11).panel-list-selected')
      end

      it "scrolls to the selected granule" do
        expect(page.execute_script(is_granule_panel_visible_script)).to be_true
      end
    end

    context "and clicking on it again" do
      before :all do
        nth_granule_list_item(10).click
        wait_for_xhr
      end

      after :all do
        nth_granule_list_item(10).click
      end

      it "removes added highlights and overlays from the granule result list" do
        expect(granule_list).to have_no_selector('.panel-list-selected')
        expect(granule_list).to have_no_selector('.panel-list-remove')
      end

      it "removes added highlights and overlays from the map" do
        expect(page).to have_selector('#map path', count: 3) # Just the spatial constraint and hover
        expect(page).to have_no_selector('#map .panel-list-remove')
        expect(page).to have_no_selector('.granule-spatial-label-temporal')
      end

      it "returns the granule ordering to its original state" do
        expect(page.execute_script(is_temporal_ordered_script)).to be_true
      end
    end
  end

  context "clicking on a granule on the map" do
    before :all do
      load_page :search, bounding_box: [0, 0, 15, 15], focus: 'C203234448-LAADS'
      map_mouseclick('#map', 2, -11)
      wait_for_xhr
    end

    after :all do
      map_mouseclick('#map', 2, -11)
      wait_for_xhr
    end

    it "highlights the selected granule in the granule list" do
      expect(granule_list).to have_selector('.panel-list-selected', count: 1)
    end

    it "highlights the selected granule on the map" do
      expect(page).to have_selector('#map path', count: 3)
    end

    it "displays a link to remove the granule in the granule list" do
      expect(granule_list).to have_link('Remove granule')
    end

    it "displays a link to remove the granule on the map" do
      expect(page).to have_selector('#map .panel-list-remove', count: 1)
    end

    it "displays the granule's temporal extents on the map" do
      expect(page).to have_selector('.granule-spatial-label-temporal', count: 1)
    end

    it "displays the granule above all other granules" do
      synchronize do
        expect(page.execute_script(is_temporal_ordered_script)).to be_false
      end
    end

    it "scrolls to the selected granule" do
      expect(page.execute_script(is_granule_panel_visible_script)).to be_true
    end

    context "and clicking on it again" do
      before :all do
        map_mouseclick('#map', 2, -11)
        wait_for_xhr
      end

      after :all do
        map_mouseclick('#map', 2, -11)
        wait_for_xhr
      end

      it "removes added highlights and overlays from the granule result list" do
        expect(granule_list).to have_no_selector('.panel-list-selected')
        expect(granule_list).to have_no_selector('.panel-list-remove')
      end

      it "removes added highlights and overlays from the map" do
        expect(page).to have_selector('#map path', count: 1) # Just the spatial constraint
        expect(page).to have_no_selector('#map .panel-list-remove')
        expect(page).to have_no_selector('.granule-spatial-label-temporal')
      end

      it "returns the granule ordering to its original state" do
        expect(page.execute_script(is_temporal_ordered_script)).to be_true
      end
    end

    context "clicking the remove icon on the map" do
      before :all do
        find_by_id("map").find('a[title="Remove granule"]').click
        wait_for_xhr
        page.execute_script("$('#map').data('map').map.panTo(new L.LatLng(2,-11))")
      end

      after :all do
        granule_list.click_link 'Filter granules'
        click_button "granule-filters-clear"
        click_button('Apply your selections')
        wait_for_xhr
        map_mouseclick('#map', 2, -11)
      end

      it "removes the granule from the list" do
        expect(page).to have_css('#granule-list .panel-list-item', count: 19)
      end
    end
  end

end
