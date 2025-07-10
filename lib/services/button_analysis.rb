#!/usr/bin/env ruby

require 'find'
require 'json'
require 'set'

# Button Analysis Tool for ConsiderIt
# This script extracts all BUTTON elements from CoffeeScript files and analyzes their styling patterns

class ButtonAnalyzer
  def initialize(client_dir = '@client')
    @client_dir = client_dir
    @buttons = []
  end

  def analyze
    puts "🔍 Analyzing ConsiderIt buttons..."
    
    find_coffee_files.each do |file|
      extract_buttons_from_file(file)
    end
    
    puts "📁 Found #{@buttons.length} buttons across #{@buttons.map { |b| b[:file] }.uniq.length} files"
    
    # Extract all CSS styles for button classes found in the codebase
    puts "🎨 Extracting CSS styles for button classes..."
    @css_styles = extract_css_styles_for_button_classes
    
    generate_report
  end

  private

  def parse_complex_class_string(class_string)
    # Handle complex className strings that may contain interpolations
    # Examples:
    # "selector_button #{if active then 'active' else ""}"
    # "dropMenu-anchor #{if @props.anchor_class_name then @props.anchor_class_name else ''}"
    # "icon CollapseList #{if is_collapsed then 'collapsed' else 'expanded'}"
    # "selector_button filter opinion_view_button #{if activated then 'active' else ''}"
    
    all_classes = []
    
    # Split by interpolation boundaries, but handle nested braces properly
    parts = []
    current_part = ""
    brace_count = 0
    i = 0
    
    while i < class_string.length
      char = class_string[i]
      next_char = i + 1 < class_string.length ? class_string[i + 1] : nil
      
      if char == '#' && next_char == '{'
        # Found start of interpolation
        if current_part.length > 0
          parts << current_part
          current_part = ""
        end
        i += 2 # Skip #{
        brace_count = 1
        
        # Read until we find the matching closing brace
        interpolation_content = ""
        while i < class_string.length && brace_count > 0
          char = class_string[i]
          if char == '{'
            brace_count += 1
          elsif char == '}'
            brace_count -= 1
          end
          
          if brace_count > 0
            interpolation_content += char
          end
          i += 1
        end
        
        # Process the interpolation content
        conditional_classes = extract_conditional_classes(interpolation_content)
        all_classes.concat(conditional_classes)
      else
        current_part += char
        i += 1
      end
    end
    
    # Add any remaining content
    if current_part.length > 0
      parts << current_part
    end
    
    # Process all non-interpolation parts as static classes
    parts.each do |part|
      if part && !part.empty?
        static_classes = part.strip.split(/\s+/).reject(&:empty?)
        all_classes.concat(static_classes)
      end
    end
    
    # Clean up and return unique classes
    all_classes.map(&:strip).reject(&:empty?).uniq
  end

  def extract_conditional_classes(interpolation)
    # Extract class names from various interpolation patterns
    classes = []
    
    # Pattern: if condition then 'class' else 'other_class'
    if match = interpolation.match(/if\s+.*?\s+then\s+['"]([^'"]*)['"]\s*else\s+['"]([^'"]*)['"]/m)
      classes << match[1] if !match[1].empty?
      classes << match[2] if !match[2].empty?
    # Pattern: if condition then 'class'
    elsif match = interpolation.match(/if\s+.*?\s+then\s+['"]([^'"]*)['"]/m)
      classes << match[1] if !match[1].empty?
    # Pattern: if condition then variable_name else 'class'
    elsif match = interpolation.match(/if\s+.*?\s+then\s+([^'"]\S+)\s+else\s+['"]([^'"]*)['"]/m)
      # For variable names, we can't easily determine the class, so skip
      classes << match[2] if !match[2].empty?
    # Pattern: if condition then variable_name (can't determine class)
    elsif match = interpolation.match(/if\s+.*?\s+then\s+([^'"]\S+)/m)
      # Skip variable references as we can't determine the actual class
    end
    
    # Split multi-class strings
    classes.flat_map { |cls| cls.split(/\s+/) }.reject(&:empty?)
  end

  def parse_conditional_class_expression(expression)
    # Parse unquoted conditional expressions like "if filter in local.filters then 'active'"
    # or "if condition then 'class1 class2' else 'class3'"
    classes = []
    
    # Pattern: if condition then 'class' else 'other_class'
    if match = expression.match(/if\s+.*?\s+then\s+['"]([^'"]*)['"]\s*else\s+['"]([^'"]*)['"]/m)
      classes << match[1] if !match[1].empty?
      classes << match[2] if !match[2].empty?
    # Pattern: if condition then 'class'
    elsif match = expression.match(/if\s+.*?\s+then\s+['"]([^'"]*)['"]/m)
      classes << match[1] if !match[1].empty?
    # Pattern: if condition then variable_name else 'class'
    elsif match = expression.match(/if\s+.*?\s+then\s+([^'"]\S+)\s+else\s+['"]([^'"]*)['"]/m)
      # For variable names, we can't easily determine the class, so skip
      classes << match[2] if !match[2].empty?
    end
    
    # Split multi-class strings and clean up
    classes.flat_map { |cls| cls.split(/\s+/) }.reject(&:empty?)
  end

  def find_style_variables(lines)
    style_variables = {}
    
    lines.each_with_index do |line, index|
      trimmed = line.strip
      
      # Look for variable assignments that might contain styles
      # Pattern: variable_name = { ... } or variable_name =
      if match = trimmed.match(/^(\w+(?:_\w+)*)\s*=\s*$/)
        variable_name = match[1]
        
        # Check if next lines contain style properties
        styles = {}
        current_line = index + 1
        base_indent = line.length - line.lstrip.length
        
        while current_line < lines.length
          next_line = lines[current_line]
          next_indent = next_line.length - next_line.lstrip.length
          next_trimmed = next_line.strip
          
          # Stop if we've outdented past the variable block or hit another assignment
          break if next_indent <= base_indent && !next_trimmed.empty? && !next_trimmed.start_with?('#')
          break if next_trimmed.match(/^\w+\s*=/)
          
          # Extract style properties from this line
          style_properties = %w[backgroundColor background border borderColor borderRadius color padding margin fontSize fontWeight textDecoration cursor display position width height opacity]
          
          style_properties.each do |prop|
            if match = next_trimmed.match(/#{prop}:\s*['"]?([^'",\n}]+)['"]?/)
              styles[prop] = match[1].strip.gsub(/[,']$/, '')
            end
          end
          
          current_line += 1
        end
        
        # Only store if we found style properties
        if styles.any?
          style_variables[variable_name] = styles
        end
      end
    end
    
    style_variables
  end

  def extract_css_styles_for_button_classes
    # Get all unique class names used by buttons
    button_classes = @buttons.map { |b| b[:class_name] }.compact.uniq
    puts "   Found #{button_classes.length} unique button classes: #{button_classes.join(', ')}"
    
    css_styles = {}
    @class_definitions = {} # Store actual CSS class definitions
    
    # Search through CoffeeScript files in loading order to preserve CSS cascade
    get_file_loading_order.each_with_index do |file, file_index|
      content = File.read(file)
      
      # Look for styles += """ blocks
      style_blocks = content.scan(/styles\s*\+=\s*"""(.*?)"""/m)
      if style_blocks.any?
        style_blocks.each_with_index do |style_block, block_index|
          parse_css_block_with_order(style_block[0], button_classes, css_styles, file_index, block_index, file)
          extract_class_definitions(style_block[0]) # Extract class definitions
        end
      end
      
      # Look for other CSS blocks in STYLE tags
      style_tag_blocks = content.scan(/STYLE\s+.*?dangerouslySetInnerHTML:\s*__html:\s*"""(.*?)"""/m)
      if style_tag_blocks.any?
        style_tag_blocks.each_with_index do |style_block, block_index|
          parse_css_block_with_order(style_block[0], button_classes, css_styles, file_index, block_index + 1000, file)
          extract_class_definitions(style_block[0]) # Extract class definitions
        end
      end
    end
    
    puts "   Extracted styles for #{css_styles.keys.length} classes"
    puts "   Extracted class definitions for #{@class_definitions.keys.length} classes: #{@class_definitions.keys.join(', ')}"
    css_styles
  end

  def extract_class_definitions(css_block)
    # Extract complete CSS class definitions for later comparison
    # Look for patterns like .btn { ... }, .like_link { ... }, etc.
    
    # Use a more robust parsing approach that handles multiple rules on the same line
    # Split by closing braces first, then parse each potential rule
    css_block.split(/\}/).each do |potential_rule|
      # Look for class definitions in this segment
      if match = potential_rule.match(/\.([a-zA-Z_-][a-zA-Z0-9_-]*)\s*\{([^}]*)$/m)
        class_name = match[1]
        properties = match[2]
        
        # Process this class definition
        process_class_definition(class_name, properties)
      end
    end
  end

  def process_class_definition(class_name, properties)
    # Skip if this class has complex selectors (like .btn:hover)
    return if class_name.include?(':') || class_name.include?(' ')
    
    # Parse the properties into a hash
    property_hash = {}
    properties.split(';').each do |prop|
      if match = prop.strip.match(/^([a-zA-Z-]+):\s*(.+)$/)
        property_name = match[1].strip
        property_value = match[2].strip
        
        # Convert CSS property names to camelCase for consistency
        camel_case_name = property_name.gsub(/-([a-z])/) { $1.upcase }
        
        # Resolve interpolations if possible
        resolved_value = resolve_css_interpolations(property_value)
        
        # Apply formatting (like adding px to fontSize)
        formatted_value = format_css_value(camel_case_name, resolved_value)
        property_hash[camel_case_name] = formatted_value
      end
    end
    
    @class_definitions[class_name] = property_hash unless property_hash.empty?
  end


  def parse_css_block(css_content, target_classes, css_styles)
    # First, resolve any CoffeeScript interpolations in the CSS
    resolved_css = resolve_css_interpolations(css_content)
    
    # Parse CSS and extract rules for our target classes
    current_selector = nil
    current_properties = []
    
    resolved_css.lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('//') # Don't skip lines starting with #
      
      # Handle lines that contain both a closing brace and a new selector
      # Example: "} .btn[disabled="true"], .btn[disabled] {"
      if line.include?('}') && line.match(/\}\s*[\.\#\w\s\[\],:()>+~"=-]+\s*\{?\s*$/)
        # Save previous rule if it matches our target classes
        if current_selector && current_properties.any?
          save_matching_css_rule(current_selector, current_properties, target_classes, css_styles)
        end
        
        # Extract the new selector from after the closing brace
        new_selector = line.gsub(/^.*?\}\s*/, '').gsub(/\s*\{\s*$/, '').strip
        current_selector = new_selector
        current_properties = []
      
      # Check if this line starts a new CSS rule (selector)
      elsif line.match(/^[\.\#\w\s\[\],:()>+~"=-]+\s*\{?\s*$/) && !line.include?(':') && !line.include?('}')
        # Save previous rule if it matches our target classes
        if current_selector && current_properties.any?
          save_matching_css_rule(current_selector, current_properties, target_classes, css_styles)
        end
        
        # Start new rule
        current_selector = line.gsub(/\s*\{\s*$/, '').strip
        current_properties = []
      elsif line == '}' || line.strip == '}'
        # End of current rule
        if current_selector && current_properties.any?
          save_matching_css_rule(current_selector, current_properties, target_classes, css_styles)
        end
        current_selector = nil
        current_properties = []
      elsif current_selector && line.include?(':') && !line.match(/^[\.\#\w\s\[\],:()>+~"=-]+\s*\{?\s*$/)
        # This is a CSS property within a rule
        current_properties << line.gsub(/[;}]+$/, '').strip
      end
    end
    
    # Handle last rule
    if current_selector && current_properties.any?
      save_matching_css_rule(current_selector, current_properties, target_classes, css_styles)
    end
  end

  def parse_css_block_with_order(css_content, target_classes, css_styles, file_index, block_index, file_path)
    # First, resolve any CoffeeScript interpolations in the CSS
    resolved_css = resolve_css_interpolations(css_content)
    
    # Parse CSS and extract rules for our target classes with line number tracking
    current_selector = nil
    current_properties = []
    base_line_number = 0
    
    # Find the line number where this CSS block starts in the original file
    file_content = File.read(file_path)
    css_start_line = file_content.lines.find_index { |line| line.include?(css_content[0..50]) } || 0
    
    resolved_css.lines.each_with_index do |line, line_index|
      line = line.strip
      next if line.empty? || line.start_with?('//') # Don't skip lines starting with #
      
      current_line_number = css_start_line + line_index
      
      # Handle lines that contain both a closing brace and a new selector
      # Example: "} .btn[disabled="true"], .btn[disabled] {"
      if line.include?('}') && line.match(/\}\s*[\.\#\w\s\[\],:()>+~"=-]+\s*\{?\s*$/)
        # Save previous rule if it matches our target classes
        if current_selector && current_properties.any?
          save_matching_css_rule_with_order(current_selector, current_properties, target_classes, css_styles, file_index, block_index, base_line_number, file_path)
        end
        
        # Extract the new selector from after the closing brace
        new_selector = line.gsub(/^.*?\}\s*/, '').gsub(/\s*\{\s*$/, '').strip
        current_selector = new_selector
        current_properties = []
        base_line_number = current_line_number
      
      # Check if this line starts a new CSS rule (selector)
      elsif line.match(/^[\.\#\w\s\[\],:()>+~"=-]+\s*\{?\s*$/) && !line.include?(':') && !line.include?('}')
        # Save previous rule if it matches our target classes
        if current_selector && current_properties.any?
          save_matching_css_rule_with_order(current_selector, current_properties, target_classes, css_styles, file_index, block_index, base_line_number, file_path)
        end
        
        # Start new rule
        current_selector = line.gsub(/\s*\{\s*$/, '').strip
        current_properties = []
        base_line_number = current_line_number
      elsif line == '}' || line.strip == '}'
        # End of current rule
        if current_selector && current_properties.any?
          save_matching_css_rule_with_order(current_selector, current_properties, target_classes, css_styles, file_index, block_index, base_line_number, file_path)
        end
        current_selector = nil
        current_properties = []
      elsif current_selector && line.include?(':') && !line.match(/^[\.\#\w\s\[\],:()>+~"=-]+\s*\{?\s*$/)
        # This is a CSS property within a rule
        current_properties << line.gsub(/[;}]+$/, '').strip
      end
    end
    
    # Handle last rule
    if current_selector && current_properties.any?
      save_matching_css_rule_with_order(current_selector, current_properties, target_classes, css_styles, file_index, block_index, base_line_number, file_path)
    end
  end

  def resolve_css_interpolations(css_content)
    # Common interpolations found in ConsiderIt CSS
    interpolation_map = {
      '#{PHONE_MEDIA}' => '@media (max-width: 480px)',
      '#{TABLET_MEDIA}' => '@media (max-width: 768px)',
      '#{mono_font()}' => '"Monaco", "Courier New", monospace',
      '#{font()}' => '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      '#{customization(\'font\')}' => '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      '#{ITEM_TEXT_WIDTH()}' => '700px',
      '#{LIST_ITEM_EXPANSION_SCALE()}' => '1.1',
      '#{ANIMATION_SPEED_ITEM_EXPANSION}' => '0.3',
      '#{COLLAPSED_MAX_HEIGHT}' => '50px',
      '#{EXPANDED_MAX_HEIGHT}' => '500px'
    }
    
    resolved = css_content.dup
    
    # Apply known interpolations
    interpolation_map.each do |interpolation, value|
      resolved.gsub!(interpolation, value)
    end
    
    # Handle remaining simple interpolations with fallbacks
    resolved.gsub!(/\#\{([^}]+)\}/) do |match|
      interpolation = $1
      
      # Try to resolve common patterns
      case interpolation
      when /^customization\(['"]([^'"]+)['"]\)/
        # customization calls - use reasonable defaults
        setting = $1
        case setting
        when 'font'
          '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
        when 'collapsed_max_height'
          '50px'
        else
          'inherit'
        end
      when /^\d+$/
        # Pure numbers
        interpolation
      when /^['\"][^'"]*['"]$/
        # Quoted strings
        interpolation.gsub(/['"]/, '')
      when /color|Color/
        # Color-related functions
        'var(--text_dark)'
      when /width|Width|size|Size/
        # Size-related functions
        'auto'
      else
        # Unknown interpolations - remove or use fallback
        puts "   Warning: Unknown interpolation #{match}, using fallback"
        'auto'
      end
    end
    
    resolved
  end

  def save_matching_css_rule(selector, properties, target_classes, css_styles)
    # Calculate CSS specificity for this rule
    specificity = calculate_css_specificity(selector)
    
    # Check if this selector matches any of our target classes
    target_classes.each do |class_name_string|
      # Split class names (like "btn AUTH_submit_button" -> ["btn", "AUTH_submit_button"])
      individual_classes = class_name_string.split(/\s+/)
      
      individual_classes.each do |individual_class|
        if selector.include?(".#{individual_class}")
          # Store both direct and contextual rules, but mark them differently
          is_direct = is_direct_class_rule(selector, individual_class)
          
          # Normalize selector for button previews - strip parent contexts for direct rules
          normalized_selector = is_direct ? normalize_selector_for_preview(selector, individual_class) : selector
          
          css_styles[class_name_string] ||= []
          css_styles[class_name_string] << {
            selector: normalized_selector,
            properties: properties.dup,
            specificity: specificity,
            is_direct_rule: is_direct,
            original_selector: selector
          }
        end
      end
    end
    
    # Also check for ancestor-dependent button rules (like "#flash .flash-close button")
    if selector.match(/\bbutton\s*$/i) && !selector.match(/^button\s*$/i)
      # This targets buttons within specific ancestors
      # Add it as a generic button rule for preview purposes
      css_styles['_ancestor_button_rules'] ||= []
      css_styles['_ancestor_button_rules'] << {
        selector: 'button',
        properties: properties.dup,
        original_selector: selector,
        specificity: specificity,
        is_direct_rule: false
      }
    end
  end

  def save_matching_css_rule_with_order(selector, properties, target_classes, css_styles, file_index, block_index, line_number, file_path)
    # Calculate CSS specificity for this rule
    specificity = calculate_css_specificity(selector)
    
    # Create a sort key that preserves the actual loading order from ConsiderIt
    sort_key = sprintf("%03d_%03d_%06d", file_index, block_index, line_number)
    
    # Check if this selector matches any of our target classes
    target_classes.each do |class_name_string|
      # Split class names (like "btn AUTH_submit_button" -> ["btn", "AUTH_submit_button"])
      individual_classes = class_name_string.split(/\s+/)
      
      individual_classes.each do |individual_class|
        if selector.include?(".#{individual_class}")
          # Store both direct and contextual rules, but mark them differently
          is_direct = is_direct_class_rule(selector, individual_class)
          
          # Normalize selector for button previews - strip parent contexts for direct rules
          normalized_selector = is_direct ? normalize_selector_for_preview(selector, individual_class) : selector
          
          css_styles[class_name_string] ||= []
          css_styles[class_name_string] << {
            selector: normalized_selector,
            properties: properties.dup,
            specificity: specificity,
            is_direct_rule: is_direct,
            original_selector: selector,
            sort_key: sort_key,
            file_index: file_index,
            block_index: block_index,
            line_number: line_number,
            file_path: file_path
          }
        end
      end
    end
    
    # Also check for ancestor-dependent button rules (like "#flash .flash-close button")
    if selector.match(/\bbutton\s*$/i) && !selector.match(/^button\s*$/i)
      # This targets buttons within specific ancestors
      # Add it as a generic button rule for preview purposes
      css_styles['_ancestor_button_rules'] ||= []
      css_styles['_ancestor_button_rules'] << {
        selector: 'button',
        properties: properties.dup,
        original_selector: selector,
        specificity: specificity,
        is_direct_rule: false,
        sort_key: sort_key,
        file_index: file_index,
        block_index: block_index,
        line_number: line_number,
        file_path: file_path
      }
    end
  end

  def calculate_css_specificity(selector)
    # CSS specificity calculation: [inline, IDs, classes, elements]
    # We don't handle inline styles here (they would be 1000)
    # Returns an array [id_count, class_count, element_count] for comparison
    
    # Clean up selector by removing pseudo-classes and pseudo-elements
    clean_selector = selector.gsub(/::[a-zA-Z-]+/, '').gsub(/:[a-zA-Z-]+(\([^)]*\))?/, '')
    
    # Count IDs (#identifier)
    id_count = clean_selector.scan(/#[a-zA-Z][a-zA-Z0-9_-]*/).length
    
    # Count classes (.class), attributes ([attr]), and pseudo-classes
    class_count = clean_selector.scan(/\.[a-zA-Z][a-zA-Z0-9_-]*/).length
    class_count += clean_selector.scan(/\[[^\]]*\]/).length
    
    # Count elements (tag names)
    # Split by spaces and other combinators, then count non-class/id/attribute parts
    parts = clean_selector.split(/[\s>+~]+/).reject(&:empty?)
    element_count = parts.count do |part|
      # Remove classes, IDs, and attributes from the part
      element_part = part.gsub(/[.#][a-zA-Z][a-zA-Z0-9_-]*/, '').gsub(/\[[^\]]*\]/, '')
      # If there's still content, it's an element
      !element_part.empty? && element_part.match(/^[a-zA-Z][a-zA-Z0-9-]*$/)
    end
    
    [id_count, class_count, element_count]
  end

  def compare_specificity(spec1, spec2)
    # Compare two specificity arrays
    # Returns -1 if spec1 < spec2, 0 if equal, 1 if spec1 > spec2
    
    (0..2).each do |i|
      if spec1[i] < spec2[i]
        return -1
      elsif spec1[i] > spec2[i]
        return 1
      end
    end
    
    0 # Equal specificity
  end

  def is_direct_class_rule(selector, class_name)
    # Check if this is a direct rule targeting the class, not a contextual rule
    # Direct rules: .btn, button.btn, .btn:hover, .btn.active
    # Contextual rules: #dashboard .btn, .container .btn, nav .btn
    
    # Remove pseudo-selectors for analysis
    clean_selector = selector.gsub(/:[\w-]+/, '')
    
    # Split by spaces to get parts
    parts = clean_selector.split(/\s+/)
    
    # Find the part that contains our target class
    target_part = parts.find { |part| part.include?(".#{class_name}") }
    return false unless target_part
    
    # If this is the only part or the first part, it's likely a direct rule
    if parts.length == 1
      return true
    end
    
    # If there are multiple parts, check if earlier parts are contextual
    target_index = parts.index(target_part)
    context_parts = parts[0...target_index]
    
    # If any context part starts with # or is a complex selector, it's contextual
    context_parts.each do |part|
      if part.start_with?('#') || part.include?('[') || part.match(/^\w+$/)
        return false
      end
    end
    
    # Otherwise, it's likely a direct rule
    true
  end

  private

  def normalize_selector_for_preview(selector, target_class)
    # Convert complex selectors to simple class selectors for previews
    # Examples:
    # ".proposal-metadata .metadata-piece" -> ".metadata-piece"
    # "button.metadata-piece" -> "button.metadata-piece" 
    # ".proposal-metadata button.metadata-piece" -> "button.metadata-piece"
    
    # Split selector into parts
    parts = selector.split(/\s+/)
    
    # Find the part that contains our target class
    target_part = parts.find { |part| part.include?(".#{target_class}") }
    
    if target_part
      # If it's just the class, keep it simple
      if target_part == ".#{target_class}"
        return ".#{target_class}"
      # If it's an element with the class (like "button.metadata-piece"), keep both
      elsif target_part.match(/^\w+\.#{Regexp.escape(target_class)}$/)
        return target_part
      # For complex cases, default to just the class
      else
        return ".#{target_class}"
      end
    else
      # Fallback to original selector
      return selector
    end
  end

  def find_coffee_files
    files = []
    Find.find(@client_dir) do |path|
      if path.end_with?('.coffee') && !skip_file?(path)
        files << path
      end
    end
    files
  end

  def get_file_loading_order
    # Order based on actual CSS loading order in ConsiderIt
    # shared.coffee is a dependency loaded first by most files
    
    # Convert to full file paths, adding files that exist
    ordered_files = []
    
    # 1. First, add shared.coffee dependencies (loaded first)
    shared_dependencies = [
      File.join(@client_dir, 'responsive_vars.coffee'),
      File.join(@client_dir, 'color.coffee')
    ]
    
    shared_dependencies.each do |file|
      ordered_files << file if File.exist?(file)
    end
    
    # 2. Then add shared.coffee itself (loaded as dependency by most files)
    shared_file = File.join(@client_dir, 'shared.coffee')
    ordered_files << shared_file if File.exist?(shared_file)
    
    # 3. Then add files in app.coffee require order (dependencies already loaded)
    app_require_order = [
      './element_viewport_positioning',
      './activerest-m',
      'dashboard/dashboard',
      './dock',
      './edit_forum',
      './auth/auth',
      './avatar',
      './browser_hacks',
      './browser_location',
      './bubblemouth',
      './edit_proposal',
      './edit_list',
      './edit_page',
      './customizations',
      './form',
      './histogram-canvas',
      './proposal_sort_and_search',
      './opinion_views',
      './tabs',
      './header',
      './footer',
      './homepage',
      './opinion_slider',
      './tooltip',
      './popover',
      './flash',
      './development',
      './su',
      './edit_point',
      './edit_comment',
      './point',
      './document',
      './statement',
      './item',
      './viewport_visibility_sensor',
      './icons',
      './google_translate',
      './new_forum_onboarding'
    ]
    
    app_require_order.each do |require_path|
      # Convert relative path to full path
      full_path = File.join(@client_dir, require_path.gsub('./', '') + '.coffee')
      # Only add if not already added (skip shared.coffee since it's already included)
      if File.exist?(full_path) && !ordered_files.include?(full_path)
        ordered_files << full_path
      end
    end
    
    # 4. Add any remaining coffee files that weren't in the require order
    remaining_files = find_coffee_files - ordered_files
    ordered_files + remaining_files.sort
  end

  def skip_file?(path)
    # Skip certain directories and files (same as color_analysis.rb)
    skip_patterns = [
      '/node_modules/',
      '/vendor/',
      '/tmp/',
      '/log/',
      '/lib/tasks/customizations/',
      '.min.js',
      '.min.css',
      '/public/build/',
      '/public/',
      'color_analysis.rb',
      'button_analysis.rb',
      "@client/histogram-legacy.coffee",
      "@client/histogram_lab.coffee",
      "@client/banner_legacy.coffee"
    ]
    
    skip_patterns.any? { |pattern| path.include?(pattern) }
  end

  def extract_buttons_from_file(file_path)
    return unless File.exist?(file_path)
    
    content = File.read(file_path)
    lines = content.lines
    
    # First pass: find all style variable definitions
    style_variables = find_style_variables(lines)
    
    lines.each_with_index do |line, index|
      next unless line.strip.match(/\bBUTTON\b/)
      
      
      button = {
        file: file_path.gsub("#{@client_dir}/", ''),
        line_number: index + 1,
        raw_line: line.chomp,
        context: extract_context(lines, index),
        styles: {},
        class_name: nil,
        purpose: 'unknown',
        text_content: nil,
        style_variables: style_variables
      }
      
      # Parse the button block
      parse_button_block(lines, index, button)
      
      @buttons << button
    end
  end

  def extract_context(lines, start_index)
    context_start = [0, start_index - 15].max  # Expand to capture ancestor elements
    context_end = [lines.length - 1, start_index + 10].min
    
    context_lines = (context_start..context_end).map do |i|
      {
        line_num: i + 1,
        content: lines[i].chomp,
        is_current: i == start_index
      }
    end
    
    # Extract DOM ancestor hierarchy
    ancestors = extract_dom_ancestors(lines, start_index)
    
    {
      lines: context_lines,
      ancestors: ancestors
    }
  end

  def extract_dom_ancestors(lines, button_line_index)
    # Find the ancestor DOM elements that contain this button by tracking actual containment
    ancestors = []
    current_element_indent = lines[button_line_index].length - lines[button_line_index].lstrip.length
    
    # Work backwards from the button to find containing elements
    (button_line_index - 1).downto(0) do |i|
      line = lines[i]
      trimmed = line.strip
      current_indent = line.length - line.lstrip.length
      
      # Skip empty lines and comments
      next if trimmed.empty? || trimmed.start_with?('#')
      
      # Look for React elements (DIV, SPAN, etc.) that might be ancestors
      if match = trimmed.match(/^(DIV|SPAN|SECTION|ARTICLE|HEADER|FOOTER|MAIN|NAV|ASIDE|UL|OL|LI|TABLE|TR|TD|TH|FORM|FIELDSET|LABEL|P|H1|H2|H3|H4|H5|H6)\b/)
        element_type = match[1].downcase
        
        # Only consider this element if it's actually an ancestor (less indented than current context)
        if current_indent < current_element_indent
          # Extract potential id and className for this element
          element_id = extract_element_id(lines, i)
          element_classes = extract_element_classes(lines, i)
          
          # Verify this element actually contains children by checking if there are more indented lines after it
          if element_contains_children(lines, i, current_indent)
            ancestors.unshift({
              element: element_type,
              id: element_id,
              classes: element_classes,
              line_number: i + 1,
              indent: current_indent
            })
            
            # Update the search context to this ancestor's level
            current_element_indent = current_indent
          end
        end
      end
      
      # Stop if we've reached the top level (no indentation)
      break if current_indent == 0
    end
    
    ancestors
  end

  def element_contains_children(lines, element_line_index, element_indent)
    # Check if there are any lines after this element that are more indented
    # This helps distinguish between sibling elements and parent elements
    
    (element_line_index + 1).upto([lines.length - 1, element_line_index + 20].min) do |i|
      line = lines[i]
      trimmed = line.strip
      current_indent = line.length - line.lstrip.length
      
      # Skip empty lines and comments
      next if trimmed.empty? || trimmed.start_with?('#')
      
      # If we find a line that's more indented, this element contains children
      if current_indent > element_indent
        return true
      end
      
      # If we find a line at the same level or less indented that contains an element,
      # this suggests the current element doesn't contain children
      if current_indent <= element_indent && trimmed.match(/^(DIV|SPAN|SECTION|ARTICLE|HEADER|FOOTER|MAIN|NAV|ASIDE|UL|OL|LI|TABLE|TR|TD|TH|FORM|FIELDSET|LABEL|P|H1|H2|H3|H4|H5|H6|BUTTON)\b/)
        return false
      end
    end
    
    # Default to false if we can't determine
    false
  end

  def extract_element_id(lines, start_index)
    # Look for id: "something" in the current element block, but be precise about scope
    current_line = start_index + 1  # Start from the line after the element declaration
    base_indent = lines[start_index].length - lines[start_index].lstrip.length
    
    # Look only in the immediate children of this element (one level deeper indentation)
    while current_line < lines.length
      line = lines[current_line]
      current_indent = line.length - line.lstrip.length
      trimmed = line.strip
      
      current_line += 1  # Increment at start to avoid infinite loops
      
      # Skip empty lines and comments
      next if trimmed.empty? || trimmed.start_with?('#')
      
      # Stop if we've moved to a different element at the same level or less indented
      if current_indent <= base_indent
        break
      end
      
      # Stop if we encounter another React element (this means we're in a child element)
      if trimmed.match(/^(DIV|SPAN|SECTION|ARTICLE|HEADER|FOOTER|MAIN|NAV|ASIDE|UL|OL|LI|TABLE|TR|TD|TH|FORM|FIELDSET|LABEL|P|H1|H2|H3|H4|H5|H6|BUTTON)\b/)
        break
      end
      
      # Only look for id properties that are immediate children (one level of indentation deeper)
      if current_indent == base_indent + 2  # CoffeeScript uses 2-space indentation
        if match = trimmed.match(/^id:\s*['"]([^'"]+)['"]/)
          return match[1]
        elsif match = trimmed.match(/^id:\s*if\s+.*?then\s*['"]([^'"]+)['"]/)
          # Handle conditional ids like: id: if !@props.no_modal then 'modal'
          return match[1]
        elsif match = trimmed.match(/^id:\s*['"]([^'"]*)\#\{/)
          # Handle interpolated ids - just take the static part
          return match[1].strip
        end
      end
    end
    
    nil
  end

  def extract_element_classes(lines, start_index)
    # Look for className: "something" in the current element block, but be precise about scope
    current_line = start_index + 1  # Start from the line after the element declaration
    base_indent = lines[start_index].length - lines[start_index].lstrip.length
    
    # Look only in the immediate children of this element (one level deeper indentation)
    while current_line < lines.length
      line = lines[current_line]
      current_indent = line.length - line.lstrip.length
      trimmed = line.strip
      
      current_line += 1  # Increment at start to avoid infinite loops
      
      # Skip empty lines and comments
      next if trimmed.empty? || trimmed.start_with?('#')
      
      # Stop if we've moved to a different element at the same level or less indented
      if current_indent <= base_indent
        break
      end
      
      # Stop if we encounter another React element (this means we're in a child element)
      if trimmed.match(/^(DIV|SPAN|SECTION|ARTICLE|HEADER|FOOTER|MAIN|NAV|ASIDE|UL|OL|LI|TABLE|TR|TD|TH|FORM|FIELDSET|LABEL|P|H1|H2|H3|H4|H5|H6|BUTTON)\b/)
        break
      end
      
      # Only look for className properties that are immediate children (one level of indentation deeper)
      if current_indent == base_indent + 2  # CoffeeScript uses 2-space indentation
        if match = trimmed.match(/^className:\s*['"]([^'"]+)['"]/)
          return match[1].split(/\s+/)
        elsif match = trimmed.match(/^className:\s*['"]([^'"]*)\#\{/)
          # Handle interpolated class names - just take the static part
          static_part = match[1].strip
          return static_part.empty? ? [] : static_part.split(/\s+/)
        end
      end
    end
    
    []
  end

  def parse_button_block(lines, start_index, button)
    current_line = start_index
    base_indent = lines[start_index].length - lines[start_index].lstrip.length
    
    while current_line < lines.length
      line = lines[current_line]
      current_indent = line.length - line.lstrip.length
      trimmed = line.strip
      
      # Stop if we've outdented past the button block
      if current_line > start_index && current_indent <= base_indent && !trimmed.empty?
        break
      end
      
      # Extract className - ONLY from the BUTTON line itself and immediate button properties
      # Completely exclude any child element lines to prevent contamination
      if trimmed.include?('className:')
        # Check if this is the BUTTON line itself
        is_button_line = current_line == start_index
        
        # Check if this is a child element line (starts with HTML element name after whitespace)
        is_child_element = trimmed.match(/^(?:I|SPAN|DIV|A|IMG|BR|HR|P|H\d|UL|LI|BUTTON|INPUT|TEXTAREA|SELECT|LABEL|FORM)\b/)
        
        # Only process className if it's either:
        # 1. On the BUTTON line itself, OR
        # 2. On a direct button property line (indented only slightly, not a child element, 
        #    and looks like a button property like "className:", "style:", "onClick:", etc.)
        is_button_property = !is_child_element && 
                            current_indent <= base_indent + 2 && 
                            trimmed.match(/^(?:className|style|onClick|onTouchEnd|onMouseEnter|onMouseLeave|onKeyDown|disabled|tabIndex|key|id|aria-)/)
        
        if is_button_line || is_button_property
        if match = trimmed.match(/className:\s*['"](.*)['"]/)
          # Handle quoted class names (both simple and complex)
          class_string = match[1]
          if class_string.include?('#{')
            # Complex case: contains interpolations
            parsed_classes = parse_complex_class_string(class_string)
            button[:class_name] = parsed_classes.join(' ') if parsed_classes.any?
          else
            # Simple case: no interpolation
            button[:class_name] = class_string
          end
        elsif match = trimmed.match(/className:\s*(if\s+.*?)(?:,|$)/)
          # Handle unquoted conditional expressions like "className: if filter in local.filters then 'active'"
          conditional_expr = match[1].strip
          parsed_classes = parse_conditional_class_expression(conditional_expr)
          button[:class_name] = parsed_classes.join(' ') if parsed_classes.any?
        elsif match = trimmed.match(/className:\s*([^'"\s,]+)/)
          # Handle simple variable references or function calls
          class_expr = match[1].strip
          # Only capture if it looks like a simple class name or variable
          if class_expr.match(/^\w+(?:[-_]\w+)*$/) || class_expr.match(/^[@\w]+(?:\.\w+)*$/)
            button[:class_name] = class_expr
          end
        end
        end
      end
      
      # Extract inline styles
      extract_styles(trimmed, button)
      
      # Check for style variable references
      extract_style_variables(trimmed, button)
      
      # Extract text content
      extract_text_content(trimmed, button)
      
      # Extract purpose from onClick handlers
      extract_purpose_from_handlers(trimmed, button)
      
      current_line += 1
    end
    
    # Infer purpose from text content if not found
    infer_purpose_from_text(button) if button[:purpose] == 'unknown'
  end

  def extract_styles(line, button)
    style_properties = %w[backgroundColor background border borderColor borderRadius color padding margin fontSize fontWeight textDecoration cursor display position width height opacity]
    
    style_properties.each do |prop|
      if match = line.match(/#{prop}:\s*(.+)$/)
        raw_value = match[1].strip
        
        # Handle conditional expressions in the value
        resolved_value = resolve_conditional_style_value(raw_value)
        
        # Only store if we got a resolved value (not nil for ignored conditionals)
        if resolved_value
          button[:styles][prop] = resolved_value
        end
      end
    end
  end

  def resolve_conditional_style_value(value)
    # Handle patterns like:
    # if condition then "value" # else "other_value"
    # if condition then "value"
    # if condition (without then - ignore)
    
    # Remove any trailing comments that aren't part of conditional
    value = value.gsub(/\s*#.*$/, '') unless value.include?('# else')
    
    # Pattern 1: if...then...else with comment
    if match = value.match(/if\s+.*?\s+then\s+(.*?)\s*#\s*else\s+(.*?)$/i)
      then_value = match[1].strip.gsub(/^['"]|['"]$/, '') # Remove quotes
      else_value = match[2].strip.gsub(/^['"]|['"]$/, '') # Remove quotes
      
      # Choose the "then" value for preview
      return then_value
    end
    
    # Pattern 2: if...then without else
    if match = value.match(/if\s+.*?\s+then\s+(.*?)$/i)
      then_value = match[1].strip.gsub(/^['"]|['"]$/, '') # Remove quotes
      
      # Use the "then" value
      return then_value
    end
    
    # Pattern 3: if condition without then (ignore the rule)
    if value.match(/if\s+.*?$/i) && !value.match(/\s+then\s+/i)
      # Ignore this rule as requested
      return nil
    end
    
    # Return original value if no conditional pattern found, removing quotes
    value.gsub(/^['"]|['"]$/, '')
  end

  def extract_style_variables(line, button)
    # Look for style: variable_name patterns
    if match = line.match(/style:\s*(\w+(?:_\w+)*)/)
      variable_name = match[1]
      
      # Check if we have this style variable definition
      if button[:style_variables] && button[:style_variables][variable_name]
        # Merge the style variable's styles into the button's styles
        button[:style_variables][variable_name].each do |prop, value|
          button[:styles][prop] = value
        end
        
        # Track that this came from a variable
        button[:style_variable_name] = variable_name
      end
    end
  end

  def extract_text_content(line, button)
    return if button[:text_content]
    
    # Check for translator calls
    if match = line.match(/translator\([^,]+,\s*['"]([^'"]+)['"]/)
      button[:text_content] = match[1]
    # Check for quoted strings
    elsif match = line.match(/['"]([^'"]+)['"]/)
      # Avoid capturing property values
      unless line.match(/:\s*['"]/)
        button[:text_content] = match[1]
      end
    end
  end

  def extract_purpose_from_handlers(line, button)
    if line.match(/onClick:|onTouchEnd:/)
      case line
      when /destroy|delete|remove|confirm/
        button[:purpose] = 'delete/destructive'
      when /save|submit/
        button[:purpose] = 'save/submit'
      when /edit|editing/
        button[:purpose] = 'edit'
      when /close|done/
        button[:purpose] = 'close/cancel'
      when /toggle|show|hide/
        button[:purpose] = 'toggle/show'
      end
    end
  end

  def infer_purpose_from_text(button)
    return unless button[:text_content]
    
    text = button[:text_content].downcase
    case text
    when /delete|remove/, 'x'
      button[:purpose] = 'delete/destructive'
    when /save|done|submit/
      button[:purpose] = 'save/submit'
    when /edit/
      button[:purpose] = 'edit'
    when /cancel|close/
      button[:purpose] = 'close/cancel'
    when /change|toggle/
      button[:purpose] = 'toggle/show'
    end
  end

  def generate_report
    # Categorize by similarity (default grouping)
    categories = categorize_by_individual_css_classes
    
    # Generate HTML report
    html_content = generate_html_report(categories)
    
    output_path = 'button_analysis.html'
    File.write(output_path, html_content)
    
    puts "\n✅ Report generated: #{output_path}"
    puts "\n📈 Summary:"
    puts "   • Total buttons: #{@buttons.length}"
    puts "   • Files with buttons: #{@buttons.map { |b| b[:file] }.uniq.length}"
    puts "   • Buttons with CSS classes: #{@buttons.count { |b| b[:class_name] }}"
    puts "   • Buttons with only inline styles: #{@buttons.count { |b| !b[:class_name] && !b[:styles].empty? }}"
    puts "   • Buttons with no styling: #{@buttons.count { |b| !b[:class_name] && b[:styles].empty? }}"
    
    puts "\n🏷️  Top CSS class categories:"
    categories.sort_by { |_, buttons| -buttons.length }.first(5).each do |css_class, buttons|
      category_name = css_class == 'no-css-class' ? 'Buttons with no CSS class' : "Class: #{css_class}"
      puts "   • #{category_name}: #{buttons.length} buttons"
    end
  end

  def categorize_by_individual_css_classes
    categories = {}
    all_css_classes = Set.new
    
    # First pass: collect all individual CSS classes
    @buttons.each do |button|
      if button[:class_name] && !button[:class_name].empty?
        classes = button[:class_name].split(/\s+/).reject(&:empty?)
        all_css_classes.merge(classes)
      end
    end
    
    # Create groups for each individual CSS class
    all_css_classes.each do |css_class|
      categories[css_class] = []
    end
    
    # Add catch-all group for buttons with no CSS classes
    categories['no-css-class'] = []
    
    # Second pass: add buttons to appropriate groups
    @buttons.each do |button|
      if button[:class_name] && !button[:class_name].empty?
        classes = button[:class_name].split(/\s+/).reject(&:empty?)
        
        # Add this button to each CSS class group it belongs to
        classes.each do |css_class|
          # Add other classes info to the button for display
          other_classes = classes - [css_class]
          button_with_context = button.dup
          button_with_context[:other_classes] = other_classes
          button_with_context[:current_group_class] = css_class
          
          categories[css_class] << button_with_context
        end
      else
        # Button has no CSS classes
        button_with_context = button.dup
        button_with_context[:other_classes] = []
        button_with_context[:current_group_class] = nil
        
        categories['no-css-class'] << button_with_context
      end
    end
    
    # Remove empty categories
    categories.reject { |_, buttons| buttons.empty? }
  end

  def categorize_by_css_class
    categories = {}
    
    @buttons.each do |button|
      # Group by CSS class name(s)
      css_class = button[:class_name] || 'no-class'
      
      categories[css_class] ||= []
      categories[css_class] << button
    end
    
    categories
  end

  def categorize_by_style
    categories = {}
    
    @buttons.each do |button|
      # Create a visual signature based on actual appearance
      visual_signature = generate_visual_signature(button)
      
      categories[visual_signature] ||= []
      categories[visual_signature] << button
    end
    
    categories
  end

  def generate_visual_signature(button)
    # Always use computed final values for accurate grouping
    # This ensures buttons with the same appearance are grouped together
    # regardless of whether styling comes from CSS classes or inline styles
    signature = {
      # Primary visual identity (most important for grouping)
      background_color: normalize_color_value(get_effective_style(button, 'backgroundColor')),
      text_color: normalize_color_value(get_effective_style(button, 'color')),
      border_style: normalize_border_style(button),
      
      # Typography (affects visual hierarchy)
      font_weight: normalize_font_weight(get_effective_style(button, 'fontWeight')),
      text_decoration: get_effective_style(button, 'textDecoration') || 'none',
      
      # Spacing (only if significantly different)
      padding: normalize_size_value(get_effective_style(button, 'padding'))
    }
    
    # Create a stable key from the signature
    signature.to_json
  end

  def get_class_definition(class_name)
    return nil if class_name.nil? || class_name == 'none'
    @class_definitions[class_name]
  end

  def get_effective_class_definition(class_names_string)
    return nil if class_names_string.nil? || class_names_string.empty?
    
    # Split multiple classes and merge their definitions
    classes = class_names_string.split(/\s+/)
    combined_definition = {}
    
    classes.each do |class_name|
      class_def = get_class_definition(class_name)
      if class_def
        # Later classes override earlier ones (CSS cascade)
        combined_definition.merge!(class_def)
      end
    end
    
    combined_definition.empty? ? nil : combined_definition
  end

  def find_meaningful_overrides(button, class_definition)
    overrides = {}
    
    # Properties that can meaningfully change visual appearance
    visual_properties = %w[backgroundColor background color textDecoration fontWeight 
                          border borderColor borderRadius padding opacity]
    
    visual_properties.each do |property|
      inline_value = button[:styles][property]
      class_value = class_definition[property]
      
      # Skip if no inline value
      next unless inline_value
      
      # Normalize both values for comparison
      normalized_inline = normalize_property_value(property, inline_value)
      normalized_class = normalize_property_value(property, class_value) if class_value
      
      # Only include if this is a meaningful override and the normalized value isn't nil
      if normalized_inline && is_meaningful_override(property, normalized_inline, normalized_class)
        overrides["#{property}_override"] = normalized_inline
      end
    end
    
    overrides
  end

  def normalize_property_value(property, value)
    return nil if value.nil?
    
    case property
    when 'backgroundColor', 'background', 'color'
      normalize_color_value(value)
    when 'fontWeight'
      normalize_font_weight(value)
    when 'padding'
      normalize_size_value(value)
    when 'opacity'
      # Ignore opacity for grouping purposes
      nil
    else
      value.to_s.downcase.strip
    end
  end

  def is_meaningful_override(property, inline_value, class_value)
    # If no class value, then any inline value is meaningful
    return true if class_value.nil?
    
    # If values are different, it's meaningful
    return true if inline_value != class_value
    
    # If they're the same, it's redundant (not meaningful)
    false
  end

  def get_effective_style(button, property)
    # Get style from inline styles first, then fall back to detected patterns
    inline_style = button[:styles][property] || button[:styles][property.gsub(/([A-Z])/, '-\1').downcase]
    if inline_style
      # Resolve CSS variables in inline styles
      return resolve_css_variable(inline_style)
    end
    
    # Check for applied context-aware styles from CSS rules
    if !button[:context_aware_styles]
      button[:context_aware_styles] = apply_context_aware_styling(button)
    end
    
    context_style = button[:context_aware_styles][property] || button[:context_aware_styles][property.gsub(/([A-Z])/, '-\1').downcase]
    if context_style
      # Resolve CSS variables in context-aware styles
      return resolve_css_variable(context_style)
    end
    
    class_inferred = infer_style_from_class(button[:class_name], property)
    if class_inferred
      # Resolve CSS variables in class-based styles too
      return resolve_css_variable(class_inferred)
    end
    
    # If no CSS class and no inline styles, this uses browser defaults for everything
    if (button[:class_name].nil? || button[:class_name].empty?) && button[:styles].empty?
      return :browser_default
    end
    
    # Has CSS class but no explicit value for this property - could be styled by the class
    nil
  end

  def normalize_color_value(color)
    return 'browser-default' if color == :browser_default
    return 'transparent' if color.nil? || color.empty?
    return 'transparent' if ['transparent', 'none', 'inherit'].include?(color.to_s.downcase)
    
    # Try to resolve CSS variables to their actual values
    if color.to_s.match(/var\(--([^)]+)\)/)
      variable_name = $1
      resolved_value = resolve_css_variable(variable_name)
      
      # If we can resolve it, use the resolved value
      if resolved_value
        return normalize_color_value(resolved_value)
      else
        # Can't resolve, but check if it's a common transparent variable
        return 'transparent' if variable_name.match(/transparent|none|clear/)
        # For comparison purposes, treat different CSS variables as different values
        return "css-var-#{variable_name}"
      end
    end
    
    return 'inherit' if color == 'inherit'
    color.to_s.downcase.gsub(/\s+/, '')
  end

  def resolve_css_variable(value)
    # Create a mapping of CSS variables to their resolved values
    # This is based on the CSS variables defined in the HTML report and ConsiderIt's color.coffee
    css_variable_map = {
      'text_light' => '#ffffff',
      'text_dark' => '#000000',
      'text_gray' => '#333333',
      'text_light_gray' => '#666666',
      'text_neutral' => '#888888',
      'focus_color' => '#456ae4',
      'selected_color' => '#DA4570',
      'bg_light' => '#ffffff',
      'bg_lightest_gray' => '#eeeeee',
      'bg_dark_gray' => '#444444',
      'brd_light_gray' => '#cccccc',
      'brd_mid_gray' => '#aaaaaa',
      'failure_color' => '#F94747',
      'success_color' => '#81c765',
      'bg_dark' => '#000000',
      'text_gray_on_dark' => '#cccccc',
      # Some variables might be used for transparent/invisible styling
      'bg_transparent' => 'transparent',
      'transparent' => 'transparent'
    }
    
    # Handle both variable names and full CSS variable references
    if value.is_a?(String)
      # Handle CSS variable references like "var(--focus_color)" or "var(--selected_color)"
      if value.match(/var\(--([^)]+)\)/)
        variable_name = $1
        resolved = css_variable_map[variable_name]
        return resolved || value
      end
      
      # Handle bare variable references (legacy behavior)
      if css_variable_map[value]
        return css_variable_map[value]
      end
    end
    
    value
  end

  def normalize_border_style(button)
    border = get_effective_style(button, 'border')
    border_color = get_effective_style(button, 'borderColor')
    
    return 'browser-default' if border == :browser_default || border_color == :browser_default
    return 'none' if border == 'none' || border == '0'
    return 'none' if border.nil? && border_color.nil?
    return 'default' if border.nil?
    
    # Normalize border to focus on visual impact
    if border.to_s.match(/\d+px/)
      thickness = border.to_s.match(/(\d+)px/)[1].to_i
      return 'thin' if thickness <= 1
      return 'thick' if thickness >= 3
      return 'medium'
    end
    
    'default'
  end

  def normalize_font_weight(weight)
    return 'browser-default' if weight == :browser_default
    return 'normal' if weight.nil? || weight.empty?
    return 'bold' if ['700', '600', 'bold', 'bolder'].include?(weight.to_s)
    return 'light' if ['300', '200', 'lighter'].include?(weight.to_s)
    'normal'
  end

  def normalize_size_value(size)
    return 'browser-default' if size == :browser_default
    return 'default' if size.nil? || size.empty?
    return 'none' if size == '0' || size == '0px'
    
    # Group similar sizes together
    if size.to_s.match(/(\d+)(px|rem|em)?/)
      value = $1.to_i
      unit = $2 || 'px'
      
      case unit
      when 'px'
        return 'small' if value <= 8
        return 'medium' if value <= 16
        return 'large' if value <= 24
        return 'xlarge'
      when 'rem', 'em'
        return 'small' if value <= 0.5
        return 'medium' if value <= 1
        return 'large' if value <= 1.5
        return 'xlarge'
      end
    end
    
    size.to_s
  end

  def extract_primary_class(class_name)
    return 'none' if class_name.nil? || class_name.empty?
    
    # Extract the most significant class for grouping
    classes = class_name.split(/\s+/)
    
    # Priority order for button classes
    primary_classes = ['btn', 'button', 'like_link', 'primary_button', 'cancel_button']
    
    found_primary = classes.find { |cls| primary_classes.include?(cls) }
    return found_primary if found_primary
    
    # Return first meaningful class (not modifiers)
    classes.reject { |cls| cls.match(/^(small|large|primary|secondary|outline)$/) }.first || 'none'
  end

  def infer_style_from_class(class_name, property)
    # Basic inference for common CSS classes
    return nil if class_name.nil?
    
    case property
    when 'textDecoration'
      return 'underline' if class_name.include?('like_link')
    when 'cursor'
      return 'pointer' if class_name.include?('btn') || class_name.include?('button')
    when 'fontWeight'
      return 'bold' if class_name.include?('btn') || class_name.include?('primary')
    end
    
    nil
  end

  def transparent_background?(button)
    bg = button[:styles]['backgroundColor'] || button[:styles]['background']
    bg == 'transparent' || bg == 'none'
  end

  def no_border?(button)
    border = button[:styles]['border']
    border == 'none' || border == '0'
  end

  def generate_category_name(style_info)
    parts = []
    
    primary_class = style_info['primary_class']
    
    # Handle class-based grouping with overrides
    if primary_class && primary_class != 'none'
      # Start with the class name
      base_name = "#{primary_class.capitalize} Buttons"
      
      # Check for meaningful overrides
      overrides = style_info.select { |key, _| key.end_with?('_override') }
      
      if overrides.empty?
        # No overrides, just the base class styling
        return base_name
      else
        # Has overrides, describe them
        override_descriptions = []
        overrides.each do |key, value|
          property = key.gsub('_override', '')
          case property
          when 'backgroundColor', 'background'
            override_descriptions << "BG: #{value}" unless value == 'transparent'
          when 'color'
            override_descriptions << "Text: #{value}" unless ['inherit', 'transparent'].include?(value)
          when 'textDecoration'
            override_descriptions << value.capitalize if value != 'none'
          when 'fontWeight'
            override_descriptions << value.capitalize if value != 'normal'
          end
        end
        
        if override_descriptions.empty?
          return base_name
        else
          return "#{base_name} + #{override_descriptions.join(' + ')}"
        end
      end
    end
    
    # Fall back to detailed analysis for buttons without recognized classes
    # Check if this is a browser default button (no styling)
    bg = style_info['background_color']
    border = style_info['border_style']
    is_browser_default = (bg == 'browser-default' && border == 'browser-default')
    
    if is_browser_default
      return 'Browser Default Buttons'
    end
    
    # Primary visual identity
    parts << 'Custom Styled Buttons'
    
    # Visual characteristics that matter
    if bg == 'browser-default'
      parts << 'Browser Default BG'
    elsif bg == 'transparent'
      parts << 'Transparent'
    elsif bg != 'transparent' && bg != 'css-var'
      parts << "BG: #{bg}"
    elsif bg == 'css-var'
      parts << 'CSS Variable BG'
    end
    
    # Text characteristics
    text_color = style_info['text_color']
    if text_color == 'browser-default'
      parts << 'Browser Default Text'
    elsif text_color == 'css-var'
      parts << 'CSS Variable Text'
    elsif text_color != 'transparent' && text_color != 'inherit'
      parts << "Text: #{text_color}"
    end
    
    # Typography
    font_weight = style_info['font_weight']
    if font_weight == 'browser-default'
      parts << 'Browser Default Weight'
    elsif font_weight == 'bold'
      parts << 'Bold'
    end
    
    if style_info['text_decoration'] == 'underline'
      parts << 'Underlined'
    end
    
    # Border
    if border == 'browser-default'
      parts << 'Browser Default Border'
    elsif border && border != 'none' && border != 'default'
      parts << "#{border.capitalize} Border"
    elsif border == 'none'
      parts << 'No Border'
    end
    
    # Size characteristics (only if present in signature)
    font_size = style_info['font_size']
    if font_size == 'browser-default'
      parts << 'Browser Default Size'
    elsif font_size && font_size != 'default'
      parts << "#{font_size.capitalize} Text"
    end
    
    padding = style_info['padding']
    if padding == 'browser-default'
      parts << 'Browser Default Padding'
    elsif padding && padding != 'default'
      parts << "#{padding.capitalize} Padding"
    end
    
    # Style variable as fallback identifier
    if style_info['style_variable'] != 'none'
      parts << "Var: #{style_info['style_variable']}"
    end
    
    # Clean up and limit length
    name = parts.join(' + ')
    
    # Simplify overly long names
    if name.length > 60
      # Keep only the most important parts
      essential_parts = []
      essential_parts << parts[0] if parts[0] # Primary class
      essential_parts.concat(parts[1..3]) if parts.length > 1 # Key visual traits
      name = essential_parts.join(' + ')
    end
    
    name
  end

  def generate_class_info_html(button)
    if button[:current_group_class]
      # Don't show the current group class since it's redundant with the group name
      # Just show "no class" if there are no other classes
      if button[:other_classes] && !button[:other_classes].empty?
        ''  # We'll show other classes separately at the bottom
      else
        '<span class="style-info">no additional classes</span>'
      end
    elsif button[:class_name] && !button[:class_name].empty?
      # Fallback for buttons not processed through new categorization
      "<span class=\"class-info\">#{button[:class_name]}</span>"
    else
      '<span class="style-info">no class</span>'
    end
  end

  def generate_other_classes_html(button)
    return '' unless button[:other_classes] && !button[:other_classes].empty?
    
    class_tags = button[:other_classes].map { |cls| 
      color = get_class_color(cls)
      "<span class=\"class-tag\" style=\"background-color: #{color}; color: white; padding: 2px 6px; border-radius: 3px; font-size: 11px; font-weight: 500; margin-right: 4px; display: inline-block;\">#{cls}</span>"
    }.join('')
    
    "<div class=\"additional-classes\" style=\"margin-top: 8px; line-height: 1.4;\">#{class_tags}</div>"
  end

  def get_class_color(class_name)
    # Generate a consistent color for each class name using a hash
    hash = class_name.bytes.sum
    hue = (hash * 137.5) % 360  # Use golden angle for good distribution
    saturation = 65 + (hash % 20)  # 65-85%
    lightness = 45 + (hash % 15)   # 45-60%
    "hsl(#{hue}, #{saturation}%, #{lightness}%)"
  end

  def generate_html_report(categories)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>ConsiderIt Button Analysis</title>
          <style>
              /* ConsiderIt CSS Variables */
              :root {
                --text_light: #ffffff;
                --text_dark: #000000;
                --text_gray: #333333;
                --text_light_gray: #666666;
                --text_neutral: #888888;
                --focus_color: #456ae4;
                --selected_color: #DA4570;
                --bg_light: #ffffff;
                --bg_lightest_gray: #eeeeee;
                --bg_dark_gray: #444444;
                --brd_light_gray: #cccccc;
                --brd_mid_gray: #aaaaaa;
                --failure_color: #F94747;
                --success_color: #81c765;
              }

              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; padding: 20px; background: #f8f9fa; }
              .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              .controls { margin: 20px 0; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              
              .button-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 12px; margin: 15px 0; }
              .button-card { background: white; padding: 12px; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); border-left: 3px solid #456ae4; cursor: pointer; transition: all 0.2s; }
              .button-card:hover { box-shadow: 0 2px 6px rgba(0,0,0,0.15); transform: translateY(-1px); }
              .button-card.expanded { transform: none; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
              
              .button-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
              .button-location { font-size: 11px; color: #666; font-family: monospace; }
              .purpose-tag { display: inline-block; padding: 1px 6px; border-radius: 8px; font-size: 10px; font-weight: 500; }
              .purpose-delete { background: #fee; color: #c33; }
              .purpose-save { background: #efe; color: #393; }
              .purpose-edit { background: #eef; color: #339; }
              .purpose-close { background: #fef; color: #939; }
              .purpose-toggle { background: #ffe; color: #993; }
              .purpose-unknown { background: #eee; color: #666; }
              
              .button-preview { display: flex; align-items: center; gap: 10px; margin-bottom: 6px; }
              
              .button-meta { font-size: 11px; color: #888; }
              .class-info { font-weight: 500; color: #456ae4; }
              .style-info { color: #666; }
              
              .code-context { background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: 'Monaco', 'Courier New', monospace; font-size: 10px; margin: 10px 0; border: 1px solid #e9ecef; display: none; cursor: pointer; }
              .code-context:hover { background: #e9ecef; }
              .button-card.expanded .code-context { display: block; }
              .context-line { margin: 1px 0; padding: 1px 3px; }
              .context-line.current { background: #fff3cd; border-left: 2px solid #ffc107; font-weight: bold; }
              .sublime-hint { font-size: 9px; color: #999; text-align: center; margin: 5px 0; }
              
              .style-category { background: white; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); overflow: hidden; }
              .category-header { background: #456ae4; color: white; padding: 12px 15px; font-weight: 600; font-size: 14px; }
              .category-content { padding: 15px; }
              
              .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
              .stat-card { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
              .stat-number { font-size: 24px; font-weight: bold; color: #456ae4; }
              .stat-label { font-size: 12px; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
              
              .hidden { display: none; }

              /* ConsiderIt Button Styles */
              button {
                line-height: 1.4;
                cursor: pointer;
                text-align: center;
                font-size: inherit;
              }

              /* Button styles are now generated dynamically from the codebase */

              /* Link-style buttons */
              button.like_link, input[type='submit'].like_link {
                background: none;
                border: none;
                text-decoration: underline;
                padding: 0px;
                color: inherit;
              }

              /* Primary button */
              .primary_button, .primary_cancel_button {
                border-radius: 16px;
                text-align: center;
                padding: 3px;
                cursor: pointer;
              }

              .primary_button {
                color: var(--text_light);
                font-size: 29px;
                margin-top: 14px;
                border: none;
                padding: 8px 36px;
                background-color: var(--focus_color);
              }

              .primary_cancel_button {
                color: var(--text_light_gray);
                margin-top: 0.5em;
                background: transparent;
                border: 1px solid var(--brd_light_gray);
              }

              /* Cancel button */
              .cancel_opinion_button {
                background: transparent;
                border: none;
                margin-top: 0.5em;
                color: var(--text_light_gray);
              }

              /* Create account button */
              button.create_account {
                background-color: var(--selected_color);
                color: var(--text_light);
                border: none;
                padding: .325rem 1.5rem .4rem;
                border-radius: .25rem;
              }

              /* Opinion view buttons */
              button.opinion_view_button {
                border: 1px solid var(--brd_light_gray);
                border-bottom-color: var(--brd_mid_gray);
                background-color: var(--bg_lightest_gray);
                border-radius: 8px;
                font-size: 12px;
                color: var(--text_dark);
                font-weight: 400;
              }

              button.opinion_view_button.filter {
                padding: 4px 12px;
                margin: 0 8px 8px 0;
              }

              button.opinion_view_button.active {
                background-color: var(--focus_color);
                color: var(--text_light);
                border-color: var(--focus_color);
              }

              /* Save opinion button */
              .save_opinion_button {
                background-color: var(--focus_color);
                color: var(--text_light);
                border: none;
                border-radius: 16px;
                font-size: 24px;
                padding: 8px 16px;
              }

              /* Give opinion button */
              .give_opinion_button {
                background-color: var(--focus_color);
                color: var(--text_light);
                padding: .25em 18px;
                margin: 0;
                font-size: 16px;
                border: none;
                border-radius: .25rem;
              }

              /* Toggle buttons */
              .toggle_buttons button {
                background-color: var(--bg_light);
                color: var(--focus_color);
                font-weight: 600;
                font-size: 12px;
                border: 1px solid var(--focus_color);
                padding: 4px 16px;
              }

              .toggle_buttons .active button {
                background-color: var(--focus_color);
                color: var(--text_light);
              }

              /* Dashboard buttons */
              #DASHBOARD-main .btn {
                background-color: var(--selected_color);
              }


              /* Dynamically extracted button class styles */
              #{generate_dynamic_css}
          </style>
      </head>
      <body>
          <div class="header">
              <h1>ConsiderIt Button Analysis</h1>
              <p>Comprehensive analysis of all BUTTON elements across the CoffeeScript codebase</p>
              
              <div class="stats">
                  <div class="stat-card">
                      <div class="stat-number">#{@buttons.length}</div>
                      <div class="stat-label">Total Buttons</div>
                  </div>
                  <div class="stat-card">
                      <div class="stat-number">#{@buttons.map { |b| b[:file] }.uniq.length}</div>
                      <div class="stat-label">Files with Buttons</div>
                  </div>
                  <div class="stat-card">
                      <div class="stat-number">#{categories.length}</div>
                      <div class="stat-label">Style Categories</div>
                  </div>
                  <div class="stat-card">
                      <div class="stat-number">#{@buttons.count { |b| b[:class_name] }}</div>
                      <div class="stat-label">Have CSS Classes</div>
                  </div>
              </div>
          </div>

          <div class="controls">
              <label><input type="radio" name="sortBy" value="file"> Sort by File</label>
              <label><input type="radio" name="sortBy" value="style" style="margin-left: 20px;" checked> Sort by Style Similarity</label>
              
              <div style="margin-top: 10px;">
                  <label>Filter by Purpose:</label>
                  <select id="purposeFilter">
                      <option value="">All Purposes</option>
                      <option value="delete/destructive">Delete/Destructive</option>
                      <option value="save/submit">Save/Submit</option>
                      <option value="edit">Edit</option>
                      <option value="close/cancel">Close/Cancel</option>
                      <option value="toggle/show">Toggle/Show</option>
                      <option value="unknown">Unknown</option>
                  </select>
              </div>
          </div>

          <div id="fileView" class="hidden">
              #{generate_file_view}
          </div>

          <div id="styleView">
              #{generate_style_view(categories)}
          </div>

          <script>
              // Sort controls
              document.querySelectorAll('input[name="sortBy"]').forEach(radio => {
                  radio.addEventListener('change', (e) => {
                      if (e.target.value === 'file') {
                          document.getElementById('fileView').classList.remove('hidden');
                          document.getElementById('styleView').classList.add('hidden');
                      } else {
                          document.getElementById('fileView').classList.add('hidden');
                          document.getElementById('styleView').classList.remove('hidden');
                      }
                  });
              });
              
              // Sublime Text integration
              function openInSublime(filePath, lineNumber) {
                  // Try to make a request to a local HTTP server that will open the file
                  fetch(`http://localhost:9999/open?file=${encodeURIComponent(filePath)}&line=${lineNumber}`)
                      .catch(() => {
                          // Fallback: try to use subl:// URL scheme
                          const sublUrl = `subl://open?url=file://${encodeURIComponent(filePath)}&line=${lineNumber}`;
                          window.location.href = sublUrl;
                      });
              }
              
              // Purpose filter
              document.getElementById('purposeFilter').addEventListener('change', (e) => {
                  const filterValue = e.target.value;
                  document.querySelectorAll('.button-card').forEach(card => {
                      const purposeTag = card.querySelector('.purpose-tag');
                      if (!filterValue || (purposeTag && purposeTag.textContent === filterValue)) {
                          card.style.display = 'block';
                      } else {
                          card.style.display = 'none';
                      }
                  });
              });
          </script>
      </body>
      </html>
    HTML
  end

  def generate_file_view
    by_file = @buttons.group_by { |b| b[:file] }
    
    html = '<h2>Buttons by File</h2>'
    
    by_file.sort.each do |file, buttons|
      html += <<~HTML
        <div class="style-category">
          <div class="category-header">
            #{file} (#{buttons.length} buttons)
          </div>
          <div class="category-content">
            <div class="button-grid">
              #{buttons.map { |button| generate_button_card(button) }.join}
            </div>
          </div>
        </div>
      HTML
    end
    
    html
  end

  def generate_style_view(categories)
    html = '<h2>Buttons by CSS Class</h2>'
    
    categories.sort_by { |_, buttons| -buttons.length }.each do |css_class, buttons|
      category_name = css_class == 'no-css-class' ? 'Buttons with no CSS class' : "Class: #{css_class}"
      
      html += <<~HTML
        <div class="style-category">
          <div class="category-header">
            #{category_name} (#{buttons.length} buttons)
          </div>
          <div class="category-content">
            <div class="button-grid">
              #{buttons.map { |button| generate_button_card(button) }.join}
            </div>
          </div>
        </div>
      HTML
    end
    
    html
  end

  def generate_dynamic_css
    return '' unless @css_styles
    
    css_output = []
    seen_selectors = Set.new
    
    # Collect all CSS rules and sort them by source order
    all_rules = []
    @css_styles.each do |class_name, rules|
      # Skip the special ancestor rules collection - these are now applied directly to buttons
      next if class_name == '_ancestor_button_rules'
      
      rules.each do |rule|
        # Only include rules that have ordering information
        if rule[:sort_key]
          all_rules << rule
        end
      end
    end
    
    # Sort rules by their source order (file order, then block order, then line number)
    all_rules.sort_by! { |rule| rule[:sort_key] }
    
    # Generate CSS in the correct order
    all_rules.each do |rule|
      # Use the original selector to preserve ancestor context
      selector = rule[:original_selector]
      
      # Skip if we've already output this exact selector
      # This prevents duplicate rules when the same selector appears for multiple button classes
      next if seen_selectors.include?(selector)
      seen_selectors.add(selector)
      
      css_output << "#{selector} {"
      rule[:properties].each do |property|
        # Filter out problematic properties for button previews
        filtered_property = filter_css_property_for_preview(property)
        css_output << "  #{filtered_property};" if filtered_property
      end
      css_output << "}"
      css_output << ""
    end
    
    # Add ancestor-dependent button rules as comments for reference
    if @css_styles['_ancestor_button_rules']
      css_output << "/* Ancestor-dependent button rules (applied directly to matching buttons) */"
      @css_styles['_ancestor_button_rules'].each do |rule|
        css_output << "/* #{rule[:original_selector]} - #{rule[:properties].length} properties */"
      end
      css_output << ""
    end
    
    css_output.join("\n")
  end

  def filter_css_property_for_preview(property)
    # Remove or modify CSS properties that would hide buttons or break previews
    return nil if property.match(/display:\s*['"]?none['"]?/i)
    return nil if property.match(/visibility:\s*['"]?hidden['"]?/i)
    return nil if property.match(/opacity:\s*['"]?0['"]?/i)
    
    # Handle conditional expressions: if condition then value # else other_value
    property = resolve_conditional_styles(property)
    
    # Force all buttons to use static positioning for grid layout
    if property.match(/position:\s*/i)
      return property.gsub(/position:\s*['"]?[^'";]*['"]?/i, 'position: static')
    end
    
    # Handle conditional display properties common in CoffeeScript
    if property.match(/display:\s*if\s+.*then\s*['"]?none['"]?/i)
      # Convert conditional display: none to display: inline-block for preview
      return property.gsub(/display:\s*if\s+.*then\s*['"]?none['"]?.*$/i, 'display: inline-block')
    end
    
    # Convert problematic display values to more useful ones for previews
    if property.match(/display:\s*['"]?block['"]?/i)
      return property.gsub(/display:\s*['"]?block['"]?/i, 'display: inline-block')
    end
    
    # Keep all other properties as-is
    property
  end

  def resolve_conditional_styles(property)
    # Handle patterns like:
    # backgroundColor: if condition then "value" # else "other_value"
    # color: if condition then "value" # else "other_value"
    # property: if condition then value
    
    # Pattern 1: if...then...else with comment
    if match = property.match(/:\s*if\s+.*?\s+then\s+(.*?)\s*#\s*else\s+(.*?)$/i)
      prop_name = property.split(':')[0].strip
      then_value = match[1].strip.gsub(/^['"]|['"]$/, '') # Remove quotes
      else_value = match[2].strip.gsub(/^['"]|['"]$/, '') # Remove quotes
      
      # Choose the "then" value for preview (could be randomized or user preference)
      return "#{prop_name}: #{then_value}"
    end
    
    # Pattern 2: if...then without else
    if match = property.match(/:\s*if\s+.*?\s+then\s+(.*?)$/i)
      prop_name = property.split(':')[0].strip
      then_value = match[1].strip.gsub(/^['"]|['"]$/, '') # Remove quotes
      
      # Use the "then" value
      return "#{prop_name}: #{then_value}"
    end
    
    # Pattern 3: if condition without then (ignore the rule)
    if property.match(/:\s*if\s+.*?$/i) && !property.match(/\s+then\s+/i)
      # Ignore this rule as requested
      return nil
    end
    
    # Return original property if no conditional pattern found
    property
  end

  def generate_button_card(button)
    purpose_class = "purpose-#{button[:purpose].gsub(/[^a-z]/, '')}"
    
    # Determine the appropriate CSS class for the button preview
    button_css_class = button[:class_name] || ''
    
    # Apply context-aware styling based on actual ancestor hierarchy
    context_aware_styles = apply_context_aware_styling(button)
    
    # Apply actual inline styles from the source code for accurate preview
    preview_style = "position: static;" # Ensure static positioning for grid layout
    
    # Apply inline styles from the button source code
    if button[:styles] && button[:styles].any?
      button[:styles].each do |style_property, style_value|
        # Skip position since we're forcing static for layout
        next if style_property == 'position'
        
        # Convert CSS variable references to actual values
        resolved_value = resolve_css_variable(style_value)
        
        # Convert camelCase to kebab-case for CSS
        css_property = style_property.gsub(/([A-Z])/, '-\1').downcase
        
        preview_style += " #{css_property}: #{resolved_value};"
      end
    end
    
    # Add disabled state styling if the button has disabled property
    if button[:raw_line].include?('disabled:')
      preview_style += " opacity: 0.5; cursor: default;"
    end
    
    <<~HTML
      <div class="button-card" onclick="this.classList.toggle('expanded')">
        <div class="button-header">
          <div class="button-location">#{button[:file]}:#{button[:line_number]}</div>
          <span class="purpose-tag #{purpose_class}">#{button[:purpose]}</span>
        </div>
        
        <div class="button-preview">
          <button#{button_css_class.empty? ? '' : " class=\"#{button_css_class}\""} style="#{preview_style}">
            #{button[:text_content] || 'Button'}
          </button>
          <div class="button-meta">
            #{generate_class_info_html(button)}
            #{button[:style_variable_name] ? "<span class=\"style-info\"> + var: #{button[:style_variable_name]}</span>" : ''}
            #{button[:styles].any? ? "<span class=\"style-info\"> + #{button[:styles].length} inline styles</span>" : ''}
            #{button[:matching_css_rules]&.any? ? "<span class=\"style-info\"> + #{button[:matching_css_rules].length} CSS rule#{button[:matching_css_rules].length > 1 ? 's' : ''}</span>" : ''}
            #{button[:context][:ancestors].any? ? "<span class=\"style-info\"> + #{button[:context][:ancestors].length} ancestor#{button[:context][:ancestors].length > 1 ? 's' : ''}</span>" : ''}
          </div>
        </div>
        
        #{generate_other_classes_html(button)}
        
        <div class="code-context" onclick="event.stopPropagation(); openInSublime('#{File.expand_path(File.join(@client_dir, button[:file]))}', #{button[:line_number]})">
          <div class="sublime-hint">Click to open in Sublime Text</div>
          
          #{generate_ancestor_hierarchy_display(button)}
          #{generate_applied_rules_display(button)}
          
          <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid #e9ecef;">
            <strong>Code Context:</strong>
          </div>
          #{button[:context][:lines].map do |line|
            current_class = line[:is_current] ? 'current' : ''
            "<div class=\"context-line #{current_class}\">
              <span style=\"color: #999; margin-right: 8px;\">#{line[:line_num]}</span>#{escape_html(line[:content])}
            </div>"
          end.join}
        </div>
      </div>
    HTML
  end

  def apply_context_aware_styling(button)
    # Apply CSS rules based on the button's actual context and ancestors
    # This method considers CSS specificity and ancestor matching
    
    applied_styles = {}
    matching_rules = []
    
    # Get all CSS rules that might apply to this button
    all_rules = []
    
    # Add class-based rules, but filter for relevance
    if button[:class_name]
      class_names = button[:class_name].split(/\s+/)
      class_names.each do |class_name|
        if @css_styles[class_name]
          @css_styles[class_name].each do |rule|
            # Only add rules that actually apply to this button
            if rule_applies_to_button(button, rule)
              all_rules << rule.merge(
                rule_type: :class_rule,
                target_class: class_name
              )
            end
          end
        end
      end
    end
    
    # Add ancestor-dependent rules that match this button's context
    if @css_styles['_ancestor_button_rules']
      @css_styles['_ancestor_button_rules'].each do |rule|
        if button_matches_ancestor_rule_with_context(button, rule)
          all_rules << rule.merge(
            rule_type: :ancestor_rule,
            target_class: 'button'
          )
        end
      end
    end
    
    # Sort rules by CSS specificity (least specific first for proper cascade)
    all_rules.sort! do |a, b|
      specificity_comparison = compare_specificity(a[:specificity], b[:specificity])
      # If specificity is the same, prefer direct rules over contextual ones
      if specificity_comparison == 0
        if a[:is_direct_rule] && !b[:is_direct_rule]
          -1
        elsif !a[:is_direct_rule] && b[:is_direct_rule]
          1
        else
          0
        end
      else
        specificity_comparison
      end
    end
    
    # Apply rules in cascade order (CSS specificity)
    all_rules.each do |rule|
      matching_rules << rule
      
      # Apply the CSS properties from this rule
      rule[:properties].each do |property|
        if property.match(/([^:]+):\s*(.+)/)
          prop_name = $1.strip
          prop_value = $2.strip
          
          # Convert CSS property names to camelCase for consistent handling
          camel_prop = prop_name.gsub(/-([a-z])/) { $1.upcase }
          
          
          # Apply the property value (later rules override earlier ones)
          applied_styles[camel_prop] = prop_value
        end
      end
    end
    
    # Store matching rules for debugging/display
    button[:matching_css_rules] = matching_rules
    
    applied_styles
  end

  def button_matches_ancestor_rule_with_context(button, rule)
    # Enhanced version that uses the actual parsed ancestor hierarchy
    # instead of just searching through text context
    
    original_selector = rule[:original_selector]
    
    # Parse the selector to understand required ancestors
    required_ancestors = parse_selector_ancestors(original_selector)
    
    # Check if the button's actual ancestors match the required ancestors
    button_ancestors = button[:context][:ancestors]
    
    # Each required ancestor must be found in the button's ancestor chain
    required_ancestors.all? do |required_ancestor|
      button_ancestors.any? do |actual_ancestor|
        ancestor_matches_requirement(actual_ancestor, required_ancestor)
      end
    end
  end

  def parse_selector_ancestors(selector)
    # Parse a CSS selector to extract the required ancestor structure
    # Example: "#flash .flash-close button" -> [{type: :id, value: "flash"}, {type: :class, value: "flash-close"}]
    
    # Split by spaces (descendant combinator)
    parts = selector.split(/\s+/)
    
    # Remove the final "button" part if it exists
    parts.pop if parts.last.downcase == 'button'
    
    ancestors = []
    
    parts.each do |part|
      # Parse each part to extract type and value
      if part.match(/^#([a-zA-Z][a-zA-Z0-9_-]*)/)
        # ID selector
        ancestors << { type: :id, value: $1 }
      elsif part.match(/^\.([a-zA-Z][a-zA-Z0-9_-]*)/)
        # Class selector
        ancestors << { type: :class, value: $1 }
      elsif part.match(/^([a-zA-Z][a-zA-Z0-9-]*)/)
        # Element selector
        ancestors << { type: :element, value: $1.downcase }
      end
    end
    
    ancestors
  end

  def ancestor_matches_requirement(actual_ancestor, required_ancestor)
    # Check if an actual ancestor matches a required ancestor
    case required_ancestor[:type]
    when :id
      actual_ancestor[:id] == required_ancestor[:value]
    when :class
      actual_ancestor[:classes].include?(required_ancestor[:value])
    when :element
      actual_ancestor[:element] == required_ancestor[:value]
    else
      false
    end
  end

  def rule_applies_to_button(button, rule)
    # Check if a CSS rule actually applies to this specific button
    original_selector = rule[:original_selector]
    
    # 1. Check element type compatibility
    # Rules like ".moderation.btn input" should not apply to BUTTON elements
    if original_selector.match(/\b(input|label|span|div|a)\b/i)
      # This rule targets a specific element type other than button
      target_element = $1.downcase
      return false unless target_element == 'button'
    end
    
    # 2. Check if this is a direct rule (like ".btn") vs contextual rule (like "#dashboard .btn")
    if rule[:is_direct_rule]
      # Direct rules always apply if element type is compatible
      return true
    else
      # Contextual rules need ancestor matching
      return button_matches_ancestor_rule_with_context(button, rule)
    end
  end

  def generate_button_css(button, context_aware_styles = {})
    # Start with the button's own inline styles
    styles = button[:styles].map do |prop, value|
      css_prop = prop.gsub(/([A-Z])/, '-\1').downcase
      css_value = format_css_value(prop, value)
      css_property = "#{css_prop}: #{css_value}"
      
      # Filter out problematic properties for button previews
      filter_css_property_for_preview(css_property)
    end.compact
    
    # Add context-aware styles (these take precedence based on CSS specificity)
    context_aware_styles.each do |prop, value|
      css_prop = prop.gsub(/([A-Z])/, '-\1').downcase
      css_value = format_css_value(prop, value)
      css_property = "#{css_prop}: #{css_value}"
      
      # Filter out problematic properties for button previews
      filtered_property = filter_css_property_for_preview(css_property)
      styles << filtered_property if filtered_property
    end
    
    # Ensure all buttons have static positioning for grid layout
    unless styles.any? { |style| style.match(/position:\s*static/i) }
      styles << 'position: static'
    end
    
    styles.join('; ')
  end

  def format_css_value(property, value)
    # Handle React/JavaScript style values that need unit conversion for CSS
    case property
    when 'fontSize'
      # React fontSize: 15 should become CSS font-size: 15px
      if value.to_s.match(/^\d+$/)
        "#{value}px"
      else
        value
      end
    else
      value
    end
  end

  def generate_ancestor_hierarchy_display(button)
    ancestors = button[:context][:ancestors]
    return '' if ancestors.empty?
    
    hierarchy_html = "<div style=\"margin-bottom: 10px;\"><strong>Ancestor Hierarchy:</strong></div>"
    hierarchy_html += "<div style=\"margin-left: 10px; font-size: 10px; color: #666;\">"
    
    ancestors.each_with_index do |ancestor, index|
      indent = "  " * index
      element_display = ancestor[:element]
      
      if ancestor[:id]
        element_display += "##{ancestor[:id]}"
      end
      
      if ancestor[:classes].any?
        element_display += ".#{ancestor[:classes].join('.')}"
      end
      
      hierarchy_html += "<div>#{indent}#{element_display} (line #{ancestor[:line_number]})</div>"
    end
    
    hierarchy_html += "</div>"
    hierarchy_html
  end

  def generate_applied_rules_display(button)
    rules = button[:matching_css_rules]
    return '' if rules.nil? || rules.empty?
    
    rules_html = "<div style=\"margin-bottom: 10px;\"><strong>Applied CSS Rules (by specificity):</strong></div>"
    rules_html += "<div style=\"margin-left: 10px; font-size: 10px; color: #666;\">"
    
    rules.each_with_index do |rule, index|
      specificity_display = rule[:specificity].join(',')
      rule_type = rule[:is_direct_rule] ? 'Direct' : 'Contextual'
      
      rules_html += "<div style=\"margin-bottom: 5px;\">"
      rules_html += "<strong>#{index + 1}. #{rule[:original_selector]}</strong> "
      rules_html += "<span style=\"color: #999;\">(#{rule_type}, specificity: #{specificity_display})</span>"
      rules_html += "<div style=\"margin-left: 10px; color: #444;\">"
      
      rule[:properties].each do |property|
        rules_html += "<div>#{property}</div>"
      end
      
      rules_html += "</div></div>"
    end
    
    rules_html += "</div>"
    rules_html
  end

  def button_matches_ancestor_rule(button, rule)
    # Parse the original selector to understand what ancestors it expects
    # Example: "#flash .flash-close button" expects an element with id="flash" 
    # containing an element with class="flash-close" containing a button
    
    original_selector = rule[:original_selector]
    
    
    # Split selector into parts (handling descendant selectors)
    selector_parts = original_selector.split(/\s+/)
    
    # Remove the final "button" part since we're checking if this button matches
    selector_parts.pop if selector_parts.last.downcase == 'button'
    
    # If no ancestor requirements, this rule doesn't apply
    return false if selector_parts.empty?
    
    
    # Check if all ancestor requirements can be found across the button's context
    # Each ancestor part needs to be found somewhere in the context
    matches_all = selector_parts.all? do |selector_part|
      found_in_context = button[:context][:lines].any? do |line|
        content = line[:content]
        
        match_result = case selector_part
        when /^#(\w+)$/
          # ID selector - look for id="something" or id: 'something'
          id_name = $1
          content.match?(/id\s*[:=]\s*['"]#{id_name}['"]/) || content.match?(/id:\s*['"]#{id_name}['"]/)
        when /^\.(\w+(?:-\w+)*)$/
          # Class selector - look for className or class attributes
          class_name = $1
          content.match?(/class(?:Name)?\s*[:=]\s*['"][^'"]*\b#{class_name}\b[^'"]*['"]/) || 
          content.match?(/class(?:Name)?\s*[:=]\s*['"]#{class_name}['"]/)
        when /^(\w+)$/
          # Element selector - look for element names
          element_name = $1.upcase
          content.match?(/\b#{element_name}\b/)
        else
          # Complex selectors - try to match literally
          content.include?(selector_part)
        end
        
        
        match_result
      end
      
      
      found_in_context
    end
    
    
    matches_all
  end

  def escape_html(text)
    text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end
end

# Run the analysis if this script is executed directly
if __FILE__ == $0
  analyzer = ButtonAnalyzer.new
  analyzer.analyze
end