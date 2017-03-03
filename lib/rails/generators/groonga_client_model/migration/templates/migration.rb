class <%= migration_class_name %> < GroongaClientModel::Migration
  def change
<%- attributes.each do |attribute| -%>
  <%- if migration_action == "add" -%>
    add_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
  <%- else -%>
    remove_column :<%= table_name %>, :<%= attribute.name %>, :<%= attribute.type %><%= attribute.inject_options %>
  <%- end -%>
<%- end -%>
  end
end
