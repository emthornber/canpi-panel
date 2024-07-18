use server::PanelList;

#[test]
fn panel_list_new() {
    let panel_dir = "tests/";
    let panel_list = PanelList::new(panel_dir);
    assert_eq!(panel_list.panels.len(), 1);
    assert!(panel_list.panels.contains_key(&1));
}
