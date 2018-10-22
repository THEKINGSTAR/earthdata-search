require 'spec_helper'

describe 'Portal collection filtering', reset: false do
  it 'Visiting an Earthdata Search portal restricts visible collections to those matching its configured filter' do
    load_page :search, portal: 'simple'

    expect(page).to have_text('1 Matching Collection')
  end
end
