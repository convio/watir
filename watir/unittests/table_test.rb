# feature tests for Tables
# Why do so many of these tests call "strip"? A distinct smell...

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') unless $SETUP_LOADED
require 'unittests/setup'

class TC_Tables < Test::Unit::TestCase
  include Watir::Exception
  
  def setup
    uses_page "table1.html"
  end
  def teardown
    browser.refresh if @reload_page
  end

  def test_has_cell
    table = browser.table(:has_cell, 'nest1')
    puts table.html
    table = browser.table(:has_cell, 'nest2')
    puts table.html

  end

  def test_exists
    assert browser.table(:id, 't1').exists?
    assert browser.table(:id, /t/).exists?
    
    assert !browser.table(:id, 'missingTable').exists?
    assert !browser.table(:id, /missing_table/).exists?
    
    assert browser.table(:index, 0 + Watir::IE.base_index).exists?
    assert !browser.table(:index, 33+ Watir::IE.base_index).exists?
  end

  tag_method :test_row_count_exceptions, :fails_on_firefox
  def test_row_count_exceptions
    assert_raises UnknownObjectException do
      browser.table(:id, 'missingTable').row_count
    end
    assert_raises UnknownObjectException do
      browser.table(:index, 66 + Watir::IE.base_index).row_count
    end
    assert_raises MissingWayOfFindingObjectException do
      browser.table(:bad_attribute, 99).row_count
    end
  end
  def test_rows
    assert_equal(2, browser.table(:index, 0 + Watir::IE.base_index).row_count)
    assert_equal(2, browser.table(:index, 0 + Watir::IE.base_index).rows.length)

    assert_equal(5, browser.table(:id, 't1').row_count)  # 4 rows and a header
    assert_equal(5, browser.table(:index, 1 + Watir::IE.base_index).row_count)  # same table as above, just accessed by index
    assert_equal(5, browser.table(:id, 't1').rows.length)

    # test the each iterator on rows - ie, go through each cell
    row = browser.table(:index,  + Watir::IE.base_index)[ + Watir::IE.base_index]
    result = []
    row.each do |cell|
      result << cell.to_s.strip
    end
    assert_equal(['Row 1 Col1', 'Row 1 Col2'], result)
    assert_equal(2, row.column_count)
  end

  tag_method :test_row_counts, :fails_on_firefox
  def test_row_counts
    table = browser.table(:id => 't2')
    assert_equal(3, table.row_count)
    assert_equal(2, table.row_count_excluding_nested_tables)
  end

  tag_method :test_dynamic_tables, :fails_on_firefox
  def test_dynamic_tables
    @reload_page = true
    t = browser.table(:id, 't1')
    assert_equal(5, t.row_count)
    browser.button(:value, 'add row').click
    assert_equal(6, t.row_count)
  end

  def test_columns
    assert_raises UnknownObjectException do
      browser.table(:id, 'missingTable').column_count
    end
    assert_raises UnknownObjectException do
      browser.table(:index, 77 + Watir::IE.base_index).column_count
    end
    assert_equal(2, browser.table(:index, 0 + Watir::IE.base_index).column_count)
    assert_equal(1, browser.table(:id, 't1').column_count)   # row one has 1 cell with a colspan of 2
  end

  def test_to_a
    expected = [ ["Row 1 Col1" , "Row 1 Col2"],
                 [ "Row 2 Col1" , "Row 2 Col2"] ]
    assert_equal(expected, browser.table(:index , 0 + Watir::IE.base_index).to_a)
  end

  def test_links_and_images_in_table
    table = browser.table(:id, 'pic_table')
    image = table[0 + Watir::IE.base_index][1 + Watir::IE.base_index].image(:index,0 + Watir::IE.base_index)
    assert_equal("106", image.width)

    link = table[0 + Watir::IE.base_index][3 + Watir::IE.base_index].link(:index,0 + Watir::IE.base_index)
    assert_equal("Google", link.innerText)
  end

  def test_cell_directly
    assert browser.cell(:id, 'cell1').exists?
    assert ! browser.cell(:id, 'no_exist').exists?
    assert_equal("Row 1 Col1", browser.cell(:id, 'cell1').to_s.strip)
  end

  def test_cell_another_way
    assert_equal( "Row 1 Col1", browser.table(:index,0 + Watir::IE.base_index)[0 + Watir::IE.base_index][0 + Watir::IE.base_index].to_s.strip)
  end

  def test_row_directly
    assert browser.row(:id, 'row1').exists?
    assert ! browser.row(:id, 'no_exist').exists?
  end
  def test_row_another_way
    assert_equal('Row 2 Col1',  browser.row(:id, 'row1')[0 + Watir::IE.base_index].to_s.strip)
  end

  tag_method :test_row_in_table, :fails_on_firefox
  def test_row_in_table
    assert_equal 'Row 2 Col1 Row 2 Col2',
      browser.table(:id, 't1').row(:id, 'row1').text.gsub(/(\r|\n)/,'')
  end

  def test_row_iterator
    t = browser.table(:index, 0 + Watir::IE.base_index)
    count = Watir::IE.base_index
    t.each do |row|
      assert("Row #{count} Col1", row[0 + Watir::IE.base_index].text)
      assert("Row #{count} Col2", row[1 + Watir::IE.base_index].text)
      count += 1
    end
  end

  def test_row_collection
    t = browser.table(:index, 0 + Watir::IE.base_index)
    t.rows.each_with_index do |row, i|
      assert("Row #{i + 1} Col1", row[0 + Watir::IE.base_index].text)
      assert("Row #{i + 1} Col2", row[1 + Watir::IE.base_index].text)
    end
  end

  tag_method :test_cell_collection, :fails_on_firefox
  def test_cell_collection
    t = browser.table(:index,0 + Watir::IE.base_index)
    contents = t.cells.collect {|c| c.text}
    assert_equal(["Row 1 Col1","Row 1 Col2","Row 2 Col1","Row 2 Col2"], contents)
  end

  tag_method :test_table_body, :fails_on_firefox
  def test_table_body
    assert_equal(1, browser.table(:index, 0 + Watir::IE.base_index).bodies.length)
    assert_equal(3, browser.table(:id, 'body_test').bodies.length)

    count = 1
    browser.table(:id, 'body_test').bodies.each do |n|
      # do something better here!
      case count
      when 1
        compare_text = "This text is in the FRST TBODY."
      when 2
        compare_text = "This text is in the SECOND TBODY."
      when 3
        compare_text = "This text is in the THIRD TBODY."
      end
      assert_equal(compare_text, n[0 + Watir::IE.base_index][0 + Watir::IE.base_index].to_s.strip )   # this is the 1st cell of the first row of this particular body
      count += 1
    end
    assert_equal( count - 1, browser.table(:id, 'body_test').bodies.length )
    assert_equal( "This text is in the THIRD TBODY." ,browser.table(:id, 'body_test' ).body(:index,2 + Watir::IE.base_index)[0 + Watir::IE.base_index][0 + Watir::IE.base_index].to_s.strip )

    # iterate through all the rows in a table body
    count = 1
    browser.table(:id, 'body_test').body(:index, 1 + Watir::IE.base_index).each do | row |
      if count == 1
        assert_equal('This text is in the SECOND TBODY.', row[0 + Watir::IE.base_index].text.strip )
      elsif count == 2
        assert_equal("This text is also in the SECOND TBODY.", row[0 + Watir::IE.base_index].text.strip )
      end
      count+=1
    end
  end

  def test_table_container
    assert_nothing_raised { browser.table(:id, 't1').html }
  end

  def test_multiple_selector
    assert_equal('Second table with css class',
      browser.table(:class => 'sample', :index => 1 + Watir::IE.base_index)[0 + Watir::IE.base_index][0 + Watir::IE.base_index].text)
  end
end

class TC_Tables_Simple < Test::Unit::TestCase
  include Watir

  def setup
    goto_page "simple_table.html"
  end

  def test_simple_table_access
    table = browser.table(:index,0 + Watir::IE.base_index)
    assert_equal("Row 3 Col1", table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].text.strip)
    assert_equal("Row 1 Col1", table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].text.strip)
    assert_equal("Row 3 Col2", table[2 + Watir::IE.base_index][1 + Watir::IE.base_index].text.strip)
    assert_equal(2, table.column_count)
  end
end
class TC_Tables_Buttons < Test::Unit::TestCase
  include Watir

  def setup
    uses_page "simple_table_buttons.html"
  end

  def test_simple_table_buttons
    table = browser.table(:index, 0 + Watir::IE.base_index)

    table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:index, 0 + Watir::IE.base_index).click
    assert(browser.text_field(:name,"confirmtext").verify_contains(/CLICK1/i))
    table[1 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:index, 0 + Watir::IE.base_index).click
    assert(browser.text_field(:name,"confirmtext").verify_contains(/CLICK2/i))

    table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:id, 'b1').click
    assert(browser.text_field(:name,"confirmtext").verify_contains(/CLICK1/i))

    assert_raises(UnknownObjectException   ) { table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:id,'b_missing').click }

    table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:index, 1 + Watir::IE.base_index).click
    assert(browser.text_field(:name,"confirmtext").verify_contains(/TOO/i))

    table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:value, "Click too").click
    assert(browser.text_field(:name,"confirmtext").verify_contains(/TOO/i))

    browser.table(:index, 0 + Watir::IE.base_index)[3 + Watir::IE.base_index][0 + Watir::IE.base_index].text_field(:index,0 + Watir::IE.base_index).set("123")
    assert(browser.text_field(:index,1 + Watir::IE.base_index).verify_contains("123"))

    # check when a cell contains 2 objects

    # if there were 2 different html objects in the same cell, some weird things happened ( button caption could change for example)
    assert_equal( 'Click ->' , browser.table(:index,0 + Watir::IE.base_index)[4 + Watir::IE.base_index][0 + Watir::IE.base_index].text_field(:index,0 + Watir::IE.base_index).value )
    browser.table(:index,0 + Watir::IE.base_index)[4 + Watir::IE.base_index][0 + Watir::IE.base_index].text_field(:index,0 + Watir::IE.base_index).click
    assert_equal( 'Click ->' , browser.table(:index,0 + Watir::IE.base_index)[4 + Watir::IE.base_index][0 + Watir::IE.base_index].text_field(:index,0 + Watir::IE.base_index).value )

    browser.table(:index,0 + Watir::IE.base_index)[4 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:index,0 + Watir::IE.base_index).click
    assert_equal( '' , browser.table(:index,0 + Watir::IE.base_index)[4 + Watir::IE.base_index][0 + Watir::IE.base_index].text_field(:index,0 + Watir::IE.base_index).value )
  end

  def test_simple_table_gif
    table = browser.table(:index, 1 + Watir::IE.base_index)
    assert_match(/1\.gif/, table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)
    assert_match(/2\.gif/, table[0 + Watir::IE.base_index][1 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)
    assert_match(/3\.gif/, table[0 + Watir::IE.base_index][2 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)

    assert_match(/1\.gif/, table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)
    assert_match(/2\.gif/, table[2 + Watir::IE.base_index][1 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)
    assert_match(/3\.gif/, table[2 + Watir::IE.base_index][2 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)

    table = browser.table(:index, 2 + Watir::IE.base_index)
    assert_match(/1\.gif/, table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)
    assert_match(/2\.gif/, table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 1 + Watir::IE.base_index).src)
    assert_match(/3\.gif/, table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 2 + Watir::IE.base_index).src)

    assert_match(/1\.gif/, table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 0 + Watir::IE.base_index).src)
    assert_match(/2\.gif/, table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 1 + Watir::IE.base_index).src)
    assert_match(/3\.gif/, table[2 + Watir::IE.base_index][0 + Watir::IE.base_index].image(:index, 2 + Watir::IE.base_index).src)
  end

  def test_table_with_hidden_or_visible_rows
    t = browser.table(:id , 'show_hide')

    # expand the table
    t.each do |r|
      r[0 + Watir::IE.base_index].image(:src, /plus/).click if r[0 + Watir::IE.base_index].image(:src, /plus/).exists?
    end

    # shrink rows 1,2,3
    count = 1
    t.each do |r|
      r[0 + Watir::IE.base_index].image(:src, /minus/).click if r[0 + Watir::IE.base_index].image(:src, /minus/).exists? and (1..3) === count
      count = 2
    end
  end

  tag_method :test_table_from_element, :fails_on_firefox
  def test_table_from_element
    button = browser.button(:id, "b1")
    table = Watir::Table.create_from_element(browser, button)

    table[1 + Watir::IE.base_index][0 + Watir::IE.base_index].button(:index, 0 + Watir::IE.base_index).click
    assert(browser.text_field(:name, "confirmtext").verify_contains(/CLICK2/i))
  end
end

class TC_Table_Columns < Test::Unit::TestCase
  include Watir::Exception
  def setup
    uses_page "simple_table_columns.html"
  end

  def test_get_columnvalues_single_column
    assert_equal(["R1C1", "R2C1", "R3C1"], browser.table(:index, 0 + Watir::IE.base_index).column_values(0))
  end

  def test_colspan
    assert_equal(2, browser.table(:index, 2 + Watir::IE.base_index)[1 + Watir::IE.base_index][0 + Watir::IE.base_index].colspan)
    assert_equal(1, browser.table(:index, 2 + Watir::IE.base_index)[0 + Watir::IE.base_index][0 + Watir::IE.base_index].colspan)
    assert_equal(3, browser.table(:index, 2 + Watir::IE.base_index)[3 + Watir::IE.base_index][0 + Watir::IE.base_index].colspan)
  end

  def test_get_columnvalues_multiple_column
    assert_equal(["R1C1", "R2C1", "R3C1"], browser.table(:index, 1 + Watir::IE.base_index).column_values(0 + Watir::IE.base_index))
    assert_equal(["R1C3", "R2C3", "R3C3"], browser.table(:index, 1 + Watir::IE.base_index).column_values(2 + Watir::IE.base_index))
  end
  
  tag_method :test_get_columnvalues_with_colspan, :fails_on_firefox
  def test_get_columnvalues_with_colspan
    assert_equal(["R1C1", "R2C1", "R3C1", "R4C1", "R5C1", "R6C2"], browser.table(:index, 2 + Watir::IE.base_index).column_values(0 + Watir::IE.base_index))
     (1..3).each{|x|assert_raises(UnknownCellException){browser.table(:index, 2 + Watir::IE.base_index).column_values(x + Watir::IE.base_index)}}
  end
  
  def test_get_rowvalues_full_row
    assert_equal(["R1C1", "R1C2", "R1C3"], browser.table(:index, 2 + Watir::IE.base_index).row_values(0 + Watir::IE.base_index))
  end
  
  def test_get_rowvalues_with_colspan
    assert_equal(["R2C1", "R2C2"], browser.table(:index, 2 + Watir::IE.base_index).row_values(1 + Watir::IE.base_index))
  end
  
  def test_getrowvalues_with_rowspan
    assert_equal(["R5C1", "R5C2", "R5C3"], browser.table(:index, 2 + Watir::IE.base_index).row_values(4 + Watir::IE.base_index))
    assert_equal(["R6C2", "R6C3"], browser.table(:index, 2 + Watir::IE.base_index).row_values(5 + Watir::IE.base_index))
  end
end

class TC_Tables_Complex < Test::Unit::TestCase
  def setup
    uses_page "complex_table.html"
  end
  
  def test_complex_table_access
    table = browser.table(:index, 0 + Watir::IE.base_index)
    assert_equal("subtable1 Row 1 Col1",table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].table(:index, 0 + Watir::IE.base_index)[0 + Watir::IE.base_index][0 + Watir::IE.base_index].text.strip)
    assert_equal("subtable1 Row 1 Col2",table[0 + Watir::IE.base_index][0 + Watir::IE.base_index].table(:index, 0 + Watir::IE.base_index)[0 + Watir::IE.base_index][1 + Watir::IE.base_index].text.strip)
    assert_equal("subtable2 Row 1 Col2",table[1 + Watir::IE.base_index][0 + Watir::IE.base_index].table(:index, 0 + Watir::IE.base_index)[0 + Watir::IE.base_index][1 + Watir::IE.base_index].text.strip)
    assert_equal("subtable2 Row 1 Col1",table[1 + Watir::IE.base_index][0 + Watir::IE.base_index].table(:index, 0 + Watir::IE.base_index)[0 + Watir::IE.base_index][0 + Watir::IE.base_index].text.strip)
  end
  
  def test_each_itterator
    # for WTR-324: keep Watir::Table.each from crashing when run on nested tables
    table = browser.table(:index, 0 + Watir::IE.base_index)
    assert_equal(table.row_count, 4)
    assert_equal(table.row_count_excluding_nested_tables, 2)
    example_row_count = 0
    assert_nothing_thrown do 
      table.each do
        example_row_count += 1
      end
    end
    assert_equal(example_row_count, 2)
  end

end
