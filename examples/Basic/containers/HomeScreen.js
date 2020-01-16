import React, { useState, useEffect } from 'react';
import {
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
  Button,
  NativeEventEmitter,
  NativeModules
} from 'react-native';

import theme from '../theme';

import Header from '../components/Header/Header';

const HomeScreen = (props) => {

  const {navigate} = props.navigation;
  const [products, setProducts] = useState([])
  const { NamiEmitter } = NativeModules;
  const eventEmitter = new NativeEventEmitter(NamiEmitter);

  const subscribeAction = () => {
      NativeModules.NamiPaywallManagerBridge.raisePaywall();
  }

  const onSessionConnect = (event) => {
	  console.log("Products changed: ", event);
    setProducts(event.products)
  }

  const onPaywallShouldRaise = (event) => {
	  console.log("Data for paywall raise ", event);
  }


  useEffect(() => {

    console.log('it run')

    // Need to find somewhere that can activate this sooner
    console.log('Nami Bridge is');
    console.log(NativeModules.NamiBridge);    

    eventEmitter.addListener('PurchasesChanged', onSessionConnect);
    eventEmitter.addListener('AppPaywallActivate', onPaywallShouldRaise);
    console.log("HavePaywallManager", NativeModules.NamiPaywallManagerBridge) // to see whats coming out the console in debug mode

    NativeModules.NamiStoreKitHelperBridge.clearBypassStoreKitPurchases();
    NativeModules.NamiStoreKitHelperBridge.bypassStoreKit(true);
    NativeModules.NamiBridge.configureWithAppID("002e2c49-7f66-4d22-a05c-1dc9f2b7f2af");

  }, []);

  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView>
        <ScrollView
          contentInsetAdjustmentBehavior="automatic"
          style={styles.scrollView}>
          <Header />
          {global.HermesInternal == null ? null : (
            <View style={styles.engine}>
              <Text style={styles.footer}>Engine: Hermes</Text>
            </View>
          )}
          <View style={styles.body}>
            <View style={styles.sectionContainer}>
            <Button title="Go to About" onPress={() => navigate('About')}/>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Introduction</Text>
              <Text style={styles.sectionDescription}>
                This application demonstrates common calls used in a Nami enabled application.
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Instructions</Text>
              <Text style={styles.sectionDescription}>
                if you suspend and resume this app three times in the simulator, an example paywall will be raised - or you can use the <Text style={styles.highlight}>Subscribe</Text> button below to raise the same paywall.
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionTitle}>Important info</Text>
              <Text style={styles.sectionDescription}>
                Any Purchase will be remembered while the application is <Text style={styles.highlight}>Active</Text>, <Text style={styles.highlight}>Suspended</Text>, <Text style={styles.highlight}>Resume</Text>,
                but cleared when the application is launched.
              </Text>
              <Text style={styles.sectionDescription}>
                Examine the application source code for more details on calls used to respond and monitor purchases.
              </Text>
            </View>
            <View style={styles.sectionContainer}>
              { products.length === 0 ? <Button title="Subscribe" onPress={subscribeAction}/>  : <Button title="Change Subscription" onPress={subscribeAction} />}
            </View>
            <View style={styles.sectionContainer}>
              <Text style={styles.sectionMiddle}>
	             Subscription is: { products.length === 0  ?  <Text style={styles.danger}>Inactive</Text>   : <Text style={styles.success}>Active</Text>}
			        </Text>
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
      </>
  );
};

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: theme.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: theme.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: theme.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: theme.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: theme.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
  sectionMiddle: {
    fontSize: 20,
    fontWeight: '700',
    textAlign: 'center',
  },
  success: {
    color: 'green'
  },
  danger: {
    color: 'red'
  }
});

export default HomeScreen;