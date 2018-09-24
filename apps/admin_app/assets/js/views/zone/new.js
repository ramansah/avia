import MainView from '../main';

export default class View extends MainView {
    mount() {
      super.mount();
  
      //Specific logic here
      $("#state-zone-list").show() ;
      $("#country-zone-list").show() ;
      $("#active-zone").on('change', function() {
        var zone_type =  this.value;
        if (zone_type == "C") {
            $("#state-zone-list").hide() ;
            $("#country-zone-list").show();
        } else if(zone_type == "S"){
            $("#country-zone-list").hide();
            $("#state-zone-list").show();
        }
        
      });      
      console.log('ZoneNewView mounted');
    }
  
    unmount() {
      super.unmount();
  
      // Specific logic here
      console.log('ZoneNewView unmounted');
    }
}
