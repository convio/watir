#--
# watir/browsers
# Define browsers supported by Watir

Watir::Browser.support :name => 'ie', :class => 'Watir::IE', 
  :library => 'watir/ie', :gem => 'watir', 
  :options => [:speed, :visible]

Watir::Browser.support :name => 'safari', :class => 'Watir::Safari',
  :library => 'safariwatir'
