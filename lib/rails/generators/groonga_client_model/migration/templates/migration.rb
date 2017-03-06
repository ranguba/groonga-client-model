class <%= migration_class_name %> < GroongaClientModel::Migration
  def change
<%- attributes.each do |attribute| -%>
  <%- case @migration_action -%>
  <%- when :add -%>
    add_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
  <%- when :remove -%>
    remove_column :<%= table_name %>, :<%= attribute.name %>
  <%- end -%>
<%- end -%>
  end
end
