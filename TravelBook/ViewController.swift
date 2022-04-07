//
//  ViewController.swift
//  TravelBook
//
//  Created by Burak Karagül on 19.01.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var notesText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    
    var selectedTitle=""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        
//        Konum verisi ne kadar keskinlikle bulunacak
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
//        Kullanıcı konumu almak için izin (Sadece uygulamayı kullandığı zaman)
        locationManager.requestWhenInUseAuthorization()
        
//        Ve konum alma işlemi
        locationManager.startUpdatingLocation()
        
//        Uzun tıklama ile pint atma işlemi gesture ekleme
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
//        Eğer ikinci sayfaya tableview yoluyla gelindiyse
        
        if selectedTitle != "" {
            //CoreData
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let stringUUID = selectedTitleID!.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringUUID)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            
            do{
            let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String{
                            
                            annotationTitle = title
                            
                        }
                        if let subtitle = result.value(forKey: "subtitle") as? String{
                            
                            annotationSubtitle = subtitle
                            
                        }
                        
                        if let latitude = result.value(forKey: "latitude") as? Double{
                            
                            annotationLatitude = latitude
                            
                        }
                        
                        if let longitude = result.value(forKey: "longitude") as? Double{
                            
                            annotationLongitude = longitude
                            
                        }
                        
//                        Annotation oluşturma ve verilerini verme
                        
                        let annotation = MKPointAnnotation()
                        annotation.title = annotationTitle
                        annotation.subtitle = annotationSubtitle
                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                        annotation.coordinate=coordinate
                        
//                        Haritaya annotation ekleme (pin)
                        
                        mapView.addAnnotation(annotation)
                        nameText.text=annotationTitle
                        notesText.text=annotationSubtitle
                        
//                        Artık veilerden birisine tıklandıysa konum almasın
                        
                        locationManager.stopUpdatingLocation()
                        
//                    Tıklanan verideki konum bilgileri alınsın ve oraya yakınlaşsın
                        
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                        
                    }
                    
                }
            }catch{
                print("error")
            }
            
            

        }
        else{
            //Add new Data
        }
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
     
        
        if gestureRecognizer.state == .began {
            
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            
            
            let touchedCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            
            
            chosenLatitude=touchedCoordinate.latitude
            chosenLongitude=touchedCoordinate.longitude
            
            
            let annotation = MKPointAnnotation()
            
            
            annotation.coordinate=touchedCoordinate
            
            
            annotation.title = nameText.text
            annotation.subtitle = notesText.text
            
            
            mapView.addAnnotation(annotation)
            
            
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        if selectedTitle == ""{
        
        
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        if annotation is MKUserLocation{
            return nil
        }

        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            
            
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.green
            
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            
            pinView?.annotation = annotation
        
        }
        
        return pinView
        
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
//                Closure
                
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        
                        
                        let item = MKMapItem(placemark: newPlacemark)
                        
                        
                        item.name = self.annotationTitle
                        
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        
                        
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
               
                
            }
            
        }
        
    }

    @IBAction func SaveButtonClicked(_ sender: Any) {
        
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(notesText.text, forKey: "subtitle")
        
        
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        
        
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("success")
        }catch{
            print ("error")
        }
/
        
        NotificationCenter.default.post(name: NSNotification.Name("NewPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
}

