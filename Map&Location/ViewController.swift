//
//  ViewController.swift
//  Map&Location
//
//  Created by Егор Никитин on 12.06.2021.
//

import UIKit
import MapKit
import CoreLocation

final class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    private var locationManager = CLLocationManager()
    
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var removeAllPointsButton: UIButton!
    
    private var points: [CLLocationCoordinate2D] = [] {
        didSet {
            if !points.isEmpty {
                removeAllPointsButton.isHidden = false
            } else if points.isEmpty {
                removeAllPointsButton.isHidden = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        
        configuringMapsAppearance()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinLocation))
        
        gestureRecognizer.minimumPressDuration = 2
        
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    private func configuringMapsAppearance() {
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
    }
    
    @IBAction func removeAllAnnotationsAction(_ sender: UIButton) {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        points.removeAll()
        mapView.removeOverlays(mapView.overlays)
    }
    
    @objc private func pinLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinates
            annotation.title = "Point"
            annotation.subtitle = "New Point"
            points.append(annotation.coordinate)
            self.mapView.addAnnotation(annotation)

            showRoute()
            
        }
    }
    
    private func showRoute() {
        if points.count <= 1 {
            guard let currentLocation = locationManager.location?.coordinate else {return}
            route(startPoint: currentLocation, endPoint: points[points.count - 1])
        } else {
            route(startPoint: points[points.count - 2], endPoint: points[points.count - 1])
        }
    }
    
    private func route(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        let startItem = MKMapItem(placemark: MKPlacemark(coordinate: startPoint))
        let endItem = MKMapItem(placemark: MKPlacemark(coordinate: endPoint))
        let request = MKDirections.Request()
        request.source = startItem
        request.destination = endItem
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let response = response else {return}
            
            if response.routes.count > 0, let responseRouts = response.routes.first {
                let route = responseRouts
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 3
        renderer.strokeColor = .blue
        return renderer
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
    }


}

