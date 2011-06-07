$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') unless $SETUP_LOADED
require 'unittests/setup'

class TC_HasCellTest < Test::Unit::TestCase
  tags :must_be_visible
  include Watir
  
  def setup
    goto_page 'has_cell.html'
  end    

  def test_flat_table
    assert_equal('flat_table', browser.table(:has_cell, 'cell text').name)
    assert_equal('flat_row', browser.row(:has_cell, 'cell text').name)
    assert_equal('flat_cell', browser.cell(:has_cell, 'cell text').name)
    assert_equal(["cell text", 'other cell'], browser.row(:has_cell, 'cell text').to_a)
    assert_equal('cell text', browser.cell(:has_cell, 'cell text').text)
  end

  def test_inner_table
    assert_equal('outer_table', browser.table(:has_cell, 'some unique text').name)
    assert_equal('inner_table_2', browser.table(:has_cell, 'some common text').name)
    assert_equal('inner_table_2', browser.table(:has_cell, 'inner cell text').name)
    assert_equal('inner_row', browser.row(:has_cell, 'inner cell text').name)
    assert_equal('inner_cell', browser.cell(:has_cell, 'inner cell text').name)
    assert_equal(["inner cell text", 'other inner cell'], browser.row(:has_cell, 'inner cell text').to_a)
    assert_equal('inner cell text', browser.cell(:has_cell, 'inner cell text').text)
  end

end