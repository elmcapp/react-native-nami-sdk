//
//  NamiBridgeUtil.m
//  RNNami
//
//  Created by Kendall Gelner on 1/9/20.
//  Copyright © 2020 Nami ML Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Nami/Nami.h>

#import "NamiBridgeUtil.h"


@implementation NamiBridgeUtil : NSObject

    + (NSDictionary<NSString *,NSString *> *) skuToSKUDict:(NamiSKU *)sku {
        NSMutableDictionary<NSString *,NSString *> *productDict = [NSMutableDictionary new];

        productDict[@"skuIdentifier"] = sku.platformID;

        SKProduct *productInt = sku.product;
        productDict[@"localizedTitle"] = productInt.localizedTitle;
        productDict[@"localizedDescription"] = productInt.localizedDescription;
        productDict[@"localizedPrice"] = productInt.localizedPrice;
        productDict[@"localizedMultipliedPrice"] = productInt.localizedMultipliedPrice;
        productDict[@"price"] = productInt.price.stringValue;
        productDict[@"priceLanguage"] = productInt.priceLocale.languageCode;
        productDict[@"priceCountry"] = productInt.priceLocale.countryCode;
        productDict[@"priceCurrency"] = productInt.priceLocale.currencyCode;

        if (@available(iOS 12.0, *)) {
            if (productInt != nil && productInt.subscriptionGroupIdentifier != nil) {
                productDict[@"subscriptionGroupIdentifier"] = [NSString stringWithString:productInt.subscriptionGroupIdentifier];
            }
        }

        if (@available(iOS 11.2, *)) {
            SKProductSubscriptionPeriod *subscriptionPeriod = productInt.subscriptionPeriod;

            if (subscriptionPeriod != NULL) {
                NSUInteger numberOfUnits = subscriptionPeriod.numberOfUnits;
                SKProductPeriodUnit periodUnit = subscriptionPeriod.unit;
                NSString *convertedUnit = @"";
                switch (periodUnit) {
                    case SKProductPeriodUnitDay:
                        convertedUnit = @"day";
                        break;
                    case SKProductPeriodUnitWeek:
                        convertedUnit = @"week";
                        break;
                    case SKProductPeriodUnitMonth:
                        convertedUnit = @"month";
                        break;
                    case SKProductPeriodUnitYear:
                        convertedUnit = @"year";
                        break;
                }

                productDict[@"numberOfUnits"] = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfUnits];
                productDict[@"periodUnit"] = convertedUnit;
            }
        }

        return productDict;
    }

 + (NSDictionary<NSString *,NSString *> *) purchaseToPurchaseDict:(NamiPurchase *)purchase {
     NSMutableDictionary<NSString *,id> *purchaseDict = [NSMutableDictionary new];
     
     purchaseDict[@"skuIdentifier"] = purchase.skuID;
     purchaseDict[@"transactionIdentifier"] = purchase.transactionIdentifier;
//     purchaseDict[@"purchaseInitiatedTimestamp"] = [self javascriptDateFromNSDate:purchase.purchaseInitiatedTimestamp];
     
     NSDate *subscriptionExpirationDate = purchase.exipres;
     if (subscriptionExpirationDate != nil) {
         purchaseDict[@"subscriptionExpirationDate"] = [self javascriptDateFromNSDate:subscriptionExpirationDate];
     }
     
     NSString *convertedSourceString = @"UNKNOWN";
     switch (purchase.purchaseSource) {
          case 0:
             convertedSourceString = @"EXTERNAL";
             break;
         case 1:
             convertedSourceString = @"NAMI_RULES";
             break;
         case 2:
             convertedSourceString = @"USER";
             break;
         default:
             break;
     }
     purchaseDict[@"purchaseSource"] =  convertedSourceString;
     
//     NamiSKU *purchaseSku = [purchase ]
     
     return purchaseDict;
 }

+ (NSDictionary<NSString *,NSString *> *) entitlementToEntitlementDict:(NamiEntitlement *)entitlement {
    NSMutableDictionary<NSString *,id> *entitlementDict = [NSMutableDictionary new];
    NSLog(@"Converting entitlement %@", entitlement);
    entitlementDict[@"referenceID"] = [entitlement referenceID];
    entitlementDict[@"namiID"] = [entitlement namiID] ? [entitlement namiID] : @"";
    entitlementDict[@"desc"] = [entitlement desc] ? [entitlement desc] : @"";
    entitlementDict[@"name"] = [entitlement name] ? [entitlement name] : @"";
    
    if (entitlementDict[@"referenceID"] == nil || [[entitlement referenceID] length] == 0) {
        NSLog(@"NamiBridge: Bad entitlement in system, empty referenceID.");
        return nil;
    }
    
    NSArray <NamiPurchase *>*activePurchases = [entitlement activePurchases];
    NSMutableArray *convertedActivePurchases = [NSMutableArray array];
    for (NamiPurchase *purchase in activePurchases) {
        NSDictionary *purchaseDict = [NamiBridgeUtil purchaseToPurchaseDict:purchase];
        if (purchaseDict != nil) {
            [convertedActivePurchases addObject:purchaseDict];
        }
    }
    entitlementDict[@"activePurchases"] = convertedActivePurchases;
    
    NSArray <NamiSKU *>*purchasedSKUs = [entitlement purchasedSKUs];
       NSMutableArray *convertedPurchasedSKUs = [NSMutableArray array];
       for (NamiSKU *sku in purchasedSKUs) {
           NSDictionary *skuDict = [NamiBridgeUtil skuToSKUDict:sku];
           if (skuDict != nil) {
               [convertedPurchasedSKUs addObject:skuDict];
           }
       }
       entitlementDict[@"purchasedSKUs"] = convertedPurchasedSKUs;
    
    
    NSArray <NamiSKU *>*relatedSKUs = [entitlement relatedSKUs];
    NSMutableArray *convertedRelatedSKUs = [NSMutableArray array];
    for (NamiSKU *sku in relatedSKUs) {
        NSDictionary *skuDict = [NamiBridgeUtil skuToSKUDict:sku];
        if (skuDict != nil) {
            [convertedRelatedSKUs addObject:skuDict];
        }
    }
    entitlementDict[@"relatedSKUs"] = convertedRelatedSKUs;
    
    NamiPurchase *lastPurchase;
    for (NamiPurchase *purchase in [entitlement activePurchases]) {
        if (lastPurchase == NULL || ([lastPurchase purchaseInitiatedTimestamp] < [purchase purchaseInitiatedTimestamp])) {
            lastPurchase = purchase;
        }
    }
    if (lastPurchase != NULL) {
//        entitlementDict[@"latestPurchase"] = [NamiBridgeUtil purchaseToPurchaseDict:lastPurchase];
    }
    
    NSString *lastPurchaseSKUID = [lastPurchase skuID];
    
    NamiSKU *lastPurchasedSKU;
    if (lastPurchaseSKUID != NULL ) {
        for (NamiSKU *sku in [entitlement purchasedSKUs]) {
            if ( [[sku platformID] isEqualToString:lastPurchaseSKUID] ) {
                lastPurchasedSKU = sku;
            }
        }
    }
    
    if (lastPurchasedSKU != NULL) {
        lastPurchasedSKU = [[entitlement purchasedSKUs] lastObject];
    }

    if (lastPurchasedSKU != NULL) {
//        entitlementDict[@"lastPurchasedSKU"] = [NamiBridgeUtil skuToSKUDict:lastPurchasedSKU];
    }
   
    return entitlementDict;
}



+ (NSString *)javascriptDateFromNSDate:(NSDate *)purchaseTimestamp {
    NSTimeZone *UTC = [NSTimeZone timeZoneWithAbbreviation: @"UTC"];
    NSISO8601DateFormatOptions options = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithDashSeparatorInDate | NSISO8601DateFormatWithColonSeparatorInTime | NSISO8601DateFormatWithTimeZone;
    
    return [NSISO8601DateFormatter stringFromDate:purchaseTimestamp timeZone:UTC formatOptions:options];
}


@end
