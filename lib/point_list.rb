
#####
# Circular, doubly linked list
##### 

class LinkedList
  include Enumerable

  ListElem = Struct.new(:obj, :prev, :next)

  def initialize(*enum)
    list = enum.size == 1 && Enumerable === enum[0] ? enum[0] : enum
    @len = list.size
    if ( @len > 0 )
      @head = ListElem.new list[0], nil, nil
      @head.next = @head.prev = @head
      list.drop(1).each {|e| append e}      
    else
      @head = nil
    end     
  end

  def count 
    @len
  end

  def insert(e, i)
    if (i == 0)
      prepend(e)
    elsif (i == @len)
      append(e)
    else
      ptr = @head
      while i > 0
        ptr = ptr.next
        i -= 1
        tmp = ListElem.new e, ptr.prev, ptr
        tmp.prev.next = tmp
        tmp.next.prev = tmp
      end
    end  
  end

  def _add(e, is_prepend) 
    if ( !@head )
      @head = ListElem.new e, nil, nil
      @head.next = @head.prev = @head      
    else
      tmp = ListElem.new e, @head.prev, @head
      tmp.prev.next = tmp
      tmp.next.prev = tmp
      @len += 1
      if (is_prepend)
        @head = tmp
      end
    end
    self    
  end
    
  def append(e)
    _add(e, false)
  end

  def prepend(e)
    _add(e, true)
  end
  
  def remove(e)
    if (@len > 1) 
      e.prev.next = e.next    
      e.next.prev = e.prev
      if (e == @head)
        @head = e.next
      end
      @len -= 1
    else
      @head = nil
      @len = 0
    end
  end
  
  def each
    ptr = @head

    while ptr != @head
      yield ptr.obj
      ptr = ptr.next
    end
  end
end


##########
# Manages 
# the points that other people have written
# but this user has not included in their position. 
# The list persists through a session. A current 
# pointer tracks position in the list. 
##########
class PointList < LinkedList
  def initialize ( options = {} )
      
    #TODO: set session_id as well...what to do when relogging in? (just reset list...not a big deal)
    @are_pros = options[:are_pros]
    
    if options[:new]
      @option_id = options[:option].id
      @key = "opt-#{@option_id}".intern
      if options[:user]
        @user_id = options[:user].id
      else
        @user_id = nil
      end      
      
      #TODO: order candidates based on batting average      
      if ( @position == 1 )
        @candidates = options[:initiative].pros_sans_user( options[:user], nil, false, true ).map {|pnt| pnt.id}
      else
        @candidates = options[:initiative].cons_sans_user( options[:user], nil, false, true ).map {|pnt| pnt.id}
      end
      
      @start = -1
      @listing = -1
      
      #if ( @user )
      #  included_points = Judgement.all( :select => 'id', :conditions => { :user_id => @user, :initiative_id => @initiative, :judgement => 1, :active => 1 })
      #  remove_included_points( included_points )
      #end
      
      save( options[:session] )
    else
      @user = options[:user]
      @initiative = options[:initiative]
      @key = "init-#{@initiative}".intern

      @start = options[:start]   
      @listing = options[:listing]     
      @candidates = options[:candidates]
    end
  end    
end