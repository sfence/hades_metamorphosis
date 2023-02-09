
function metamorphosis.add_metamorphosis_report(node_name, report)
  local def = minetest.registered_nodes[node_name]
  if def._metamorphosis_report then
    report = def._metamorphosis_report.."\n\n"..report
  end
  minetest.override_item(node_name, {
      _metamorphosis_report = report
    })
end

