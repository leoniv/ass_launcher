# encoding: utf-8

# Monkey patch for WIN32OLE class
# - Define dummy class for Linux. Fail +NotImplementedError+ in constructor.
#
# - Patch for have chanse to close connection with 1C infobase in class
#   {AssLauncher::Enterprise::Ole::IbConnection IBConnector}. For this reason
#   overload
#   method +WIN32OLE#method_missing+ and hold Ole object refs retuned from ole
#   method into {#__objects__} array.
#   {AssLauncher::Enterprise::Ole::IbConnection IBConnector}
#   when close connection call
#   {#\_\_ass_ole_free\_\_} and try to ole_free for all in {#__objects__} array.
# @see AssLauncher::Enterprise::Ole::IbConnection#__close__
class WIN32OLE
  # :nocov:
  if AssLauncher::Support::Platforms.linux?
    def initialize(*_)
      fail NotImplementedError, 'WIN32OLE undefined for this machine'
    end

    # For tests
    def method_missing(*args)
      args[1]
    end
  else
    require 'win32ole' unless AssLauncher::Platform.linux?
    @win32ole_loaded = true # for tests zonde
  end
  # :nocov:

  # Hold created Ole objects
  # @return [Array]
  # @api private
  def __objects__
    @__objects__ ||= []
  end

  # @note WIN32OLE avtomaticaly wrapp Ruby objects into WIN32OLE class
  #  when they passed as parameter.
  #  When passed object retuns on Ruby side he will keep as WIN32OLE
  #
  # True if real object is Ruby object
  def __ruby__?
    ole_respond_to? :object_id
  end

  # @note (see #__ruby__?)
  # Return Ruby object wrapped in to WIN32OLE. If {#__ruby__?} is *false*
  # return *self*
  # @return [Object, self]
  def __real_obj__
    return self unless __ruby__?
    ObjectSpace._id2ref(invoke :object_id)
  end

  # @api private
  # Call ole_free for all created chiled Ole objects then free self
  def __ass_ole_free__
    @__objects__ = __ass_ole_free_objects__
    self.class.__ass_ole_free__(self)
  end

  # Free created chiled Ole objects
  def __ass_ole_free_objects__
    __objects__.each do |o|
      o.send :__ass_ole_free__ if o.is_a? WIN32OLE
    end
    nil
  end
  private :__ass_ole_free_objects__

  # @api private
  # Try call ole_free for ole object
  # @param obj [WIN32OLE] object for free
  def self.__ass_ole_free__(obj)
    return if WIN32OLE.ole_reference_count(obj) <= 0
    obj.ole_free
  end

  # @!method method_missing(*args)
  # overload {WIN32OLE#method_missing} and hold Ole object into
  # {#__objects__} array if called Ole method return Ole object
  old_method_missing = instance_method(:method_missing)
  define_method(:method_missing) do |*args|
    # :nocov:
    o = old_method_missing.bind(self).call(*args)
    __objects__ << o if o.is_a? WIN32OLE
    o
    # :nocov:
  end
end
