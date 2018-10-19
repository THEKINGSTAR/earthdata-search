require 'spec_helper'

describe 'Collections Collapsed View', reset: false do
  context 'on the search results screen' do
    before :all do
      Capybara.reset_sessions!
      load_page :search, env: :sit
    end

    it 'shows the expanded collections list by default' do
      height = page.evaluate_script('$("#collection-results").height()')
      expect(height).to be > 350
      expect(page).to have_css('.is-master-overlay-maximized')
    end

    it 'displays a minimize button for the collections list' do
      expect(page).to have_link('Minimize')
    end

    it 'displays no close button for the collections list' do
      expect(collection_results).to have_no_css('.master-overlay-close')
    end

    context 'clicking the minimize button for the collections list' do
      before :all do
        click_link 'Minimize'
      end

      it 'displays a narrower view of collections' do
        height = page.evaluate_script('$("#collection-results").height()')
        expect(height).to be < 350
      end
    end
  end
end
